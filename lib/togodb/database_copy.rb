module Togodb
  class DatabaseCopy
    include Togodb::DB::Pgsql
    include D2RQMapper

    class << self
      def total_key(key)
        "dbcopy_#{key}_total"
      end

      def populated_key(key)
        "dbcopy_#{key}_populated"
      end

      def warning_msg_key(key)
        "dbcopy_#{key}_warning"
      end

      def error_msg_key(key)
        "dbcopy_#{key}_error"
      end

      def dst_db_id_key(key)
        "dbcopy_#{key}_dst_db_id"
      end
    end

    def initialize(src_dbid, dst_dbname, copy_data, user_id, authorized_users, key = nil)
      @src_dbid = src_dbid
      @src_table = TogodbTable.find(@src_dbid)
      @togodb_page = TogodbPage.find_by_table_id(@src_dbid)

      @dst_dbname = dst_dbname
      @copy_data = copy_data

      @user_id = user_id

      @authorized_users = if authorized_users.is_a?(Array)
                            authorized_users.map(&:to_i)
                          else
                            []
                          end

      @key = key

      @redis = Resque.redis
      @redis.set total_key, 1
      @redis.set populated_key, 0
    end

    def run
      src_table_name = @src_table.name

      if @copy_data
        @redis.set total_key, total_records
        per_copy = num_records_per_copy
      else
        per_copy = 0
      end

      num_copied = 0
      ActiveRecord::Base.transaction do
        dst_table = copy_table_record(@src_table)
        @redis.set dst_db_id_key, dst_table.id if @copy_data

        copy_column_record(@src_table.columns, dst_table.id)

        update_table = false
        %w(record_name_col_id sort_col_id pkey_col_id).each do |attr_name|
          col_id = @src_table.__send__(attr_name)
          unless col_id.nil?
            s_column = TogodbColumn.find(col_id)
            d_column = TogodbColumn.where(name: s_column.name, table_id: dst_table.id).first
            eval "dst_table.#{attr_name} = d_column.id"
            update_table = true
          end
        end
        dst_table.save! if update_table

        copy_role_record(@src_table.id, dst_table.id)
        copy_data_release_record(@src_table.id, dst_table.id)
        copy_page_record(@src_table.id, dst_table.id)
        copy_db_metadata_record(@src_table.id, dst_table.id)

        prev_pct = 0
        num_copied = copy_table(src_table_name, @dst_dbname, per_copy) do |num|
          cur_pct = (num.to_f / total_records.to_f * 100).to_i
          if prev_pct < cur_pct
            @redis.set populated_key, num if prev_pct < cur_pct
            prev_pct = cur_pct
          end
        end

        if @copy_data
          dst_table.insert_column_values
          @redis.set total_key, num_copied
          @redis.set populated_key, num_copied
        else
          @redis.set total_key, 1
          @redis.set populated_key, 1
        end
      end

      setup_new_mapping_for_togodb(@dst_dbname, @user_id)
    rescue => e
      puts e.backtrace.join("\n")
      @redis.set total_key, 1
      @redis.set populated_key, 1
      @redis.set error_msg_key, "#$!"
    end

    def copy_table_record(src_table)
      dst_table = TogodbTable.new
      dst_table.name = @dst_dbname
      dst_table.page_name = @dst_dbname
      dst_table.dl_file_name = @dst_dbname
      dst_table.enabled = false
      dst_table.imported = src_table.imported
      dst_table.sortable = src_table.sortable
      dst_table.record_name = src_table.record_name
      #dst_table.confirm_licence = src_table.confirm_licence
      dst_table.disable_sort = src_table.disable_sort

      dst_table.num_records = if @copy_data
                                src_table.num_records
                              else
                                0
                              end

      dst_table.creator_id = @user_id

      now = Time.now.utc
      dst_table.created_at = now
      dst_table.updated_at = now

      dst_table.save!

      dst_table
    end

    def copy_column_record(columns, dst_table_id)
      @new_columns_map = {}
      columns.each do |column|
        new_column = TogodbColumn.new
        new_column.table_id = dst_table_id
        new_column.name = column.name
        new_column.internal_name = column.internal_name
        new_column.data_type = column.data_type
        new_column.label = column.label
        new_column.enabled = column.enabled
        new_column.actions = column.actions
        new_column.roles = column.roles
        new_column.position = column.position
        new_column.html_link_prefix = column.html_link_prefix
        new_column.html_link_suffix = column.html_link_suffix
        new_column.list_disp_order = column.list_disp_order
        new_column.show_disp_order = column.show_disp_order
        new_column.dl_column_order = column.dl_column_order
        new_column.other_type = column.other_type
        new_column.web_services = column.web_services
        new_column.num_decimal_places = column.num_decimal_places
        new_column.num_integer_digits = column.num_integer_digits
        new_column.num_fractional_digits = column.num_fractional_digits

        new_column.save!

        @new_columns_map[new_column.name] = new_column.id
      end
    end

    def copy_role_record0(src_table_id, dst_table_id)
      dst_table = TogodbTable.find(dst_table_id)
      user = TogodbUser.find(@user_id)
      TogodbRole.instance(dst_table, user).admin!
    end

    def copy_role_record(src_table_id, dst_table_id)
      return if @authorized_users.empty?

      src_table = TogodbTable.find(src_table_id)
      attr_names = TogodbRole.column_names - %w(id table_id)
      @authorized_users.each do |authorized_user_id|
        next if @user_id == authorized_user_id

        if src_table.creator_id == authorized_user_id
          TogodbRole.create_admin_role!(dst_table_id, authorized_user_id)
        else
          role = TogodbRole.find_by(table_id: src_table_id, user_id: authorized_user_id)
          if role
            new_attrs = {}
            attr_names.each do |name|
              new_attrs[name] = role[name]
            end
            new_attrs['table_id'] = dst_table_id
            TogodbRole.create!(new_attrs)
          end
        end
      end
    end

    def copy_data_release_record(src_table_id, dst_table_id)
      attr_names = TogodbDataset.column_names - %w(id table_id columns output_file_path created_at updated_at)
      datasets = TogodbDataset.where(table_id: src_table_id).order(:id)
      datasets.each do |dataset|
        new_attrs = { table_id: dst_table_id }
        col_ids = []
        dataset.columns.split(',').each do |col_id|
          togodb_column = TogodbColumn.find(col_id.to_i)
          col_ids << @new_columns_map[togodb_column.name].to_s if togodb_column
        end
        new_attrs[:columns] = col_ids.join(',')
        attr_names.each do |attr_name|
          new_attrs[attr_name.to_sym] = dataset[attr_name]
        end
        TogodbDataset.create!(new_attrs)
      end
    end

    def copy_page_record(src_table_id, dst_table_id)
      return unless @togodb_page

      attr_names = %w(view_css view_header view_body show_css show_header show_body quickbrowse)

      new_attrs = {}
      attr_names.each do |attr_name|

        value = eval("replace_#{attr_name}")
        new_attrs[attr_name] = value
      rescue
        new_attrs[attr_name] = @togodb_page[attr_name]

      end

      rest_attr_names = TogodbPage.column_names - attr_names - %w(id table_id created_at updated_at)
      rest_attr_names.each do |attr_name|
        new_attrs[attr_name] = @togodb_page[attr_name]
      end
      new_attrs['table_id'] = dst_table_id

      TogodbPage.create!(new_attrs)
    end

    def copy_db_metadata_record(src_table_id, dst_table_id)
      attr_names = TogodbDBMetadata.column_names - %w(id table_id created_at updated_at)
      db_metadata = TogodbDBMetadata.find_by_table_id(src_table_id)
      return unless db_metadata

      new_attrs = {}
      attr_names.each do |name|
        new_attrs[name] = db_metadata[name]
      end
      new_attrs['table_id'] = dst_table_id
      TogodbDBMetadata.create!(new_attrs)
    end

    def copy_data(src_table_name, dst_table_name)
      copy_all_records(src_table_name, dst_table_name, 10000, nil)
    end

    def create_data_release_record(table_id)
      Togodb::DataRelease.create_default_dataset(table_id)
    end

    def replace_view_css
      value = @togodb_page.view_css

      value
    end

    def replace_view_header
      value = @togodb_page.view_header

      value = value.gsub(view_css_url_regexp) { |w| w.gsub($1, @dst_dbname) }

      value
    end

    def replace_view_body
      value = @togodb_page.view_body

      value = value.gsub(view_table_regexp) { |w| w.gsub($1, @dst_dbname) }
      value = value.gsub(flexigrid_js_regexp) { |w| w.gsub($1, @dst_dbname) }

      value
    end

    def replace_show_css
      value = @togodb_page.show_css

      value
    end

    def replace_show_header
      value = @togodb_page.show_header

      value = value.gsub(show_css_url_regexp) { |w| w.gsub($1, @dst_dbname) }

      value
    end

    def replace_show_body
      value = @togodb_page.show_body

      value = value.gsub(record_name_regexp) { |s| s.gsub($1, @dst_dbname) }
      @src_table.columns.each do |column|
        value = value.gsub(show_elem_id_regexp(column.name)) { |w| w.gsub($1, @dst_dbname) }
      end

      value
    end

    def replace_quickbrowse
      value = @togodb_page.quickbrowse

      value = value.gsub(quickbrowse_regexp) { |s| s.gsub($1, @dst_dbname) }
      @src_table.columns.each do |column|
        value = value.gsub(show_elem_id_regexp(column.name)) { |w| w.gsub($1, @dst_dbname) }
      end

      value
    end

    def view_css_url_regexp
      %r{/togodb/view/(#{@src_table.name})\.css}
    end

    def show_css_url_regexp
      %r{/togodb/show/(#{@src_table.name})\.css}
    end

    def view_table_regexp
      /id\s*\=\s*[\"\']togodb\-(#{@src_table.name})[\"\']/
    end

    def flexigrid_js_regexp
      %r{src\s*=\s*[\"\']/togodb/flexigrid/(#{@src_table.name}).js}
    end

    def record_name_regexp
      /id\s*=s*[\"\']togodb\-(#{@src_table.name})\-record_name[\"\']/
    end

    def show_elem_id_regexp(col_name)
      /id\s*=\s*[\"\']togodb\-(#{@src_table.name})\-#{col_name}\-(label|value)[\"\']/
    end

    def quickbrowse_regexp
      /id\s*=\s*[\"\']togodb\-quickbrowse\-(#{@src_table.name})(\-html\-cache){0,1}[\"\']/
    end

    def total_key
      self.class.total_key(@key)
    end

    def populated_key
      self.class.populated_key(@key)
    end

    def warning_msg_key
      self.class.warning_msg_key(@key)
    end

    def error_msg_key
      self.class.error_msg_key(@key)
    end

    def dst_db_id_key
      self.class.dst_db_id_key(@key)
    end

    def protocol
      @protocol ||= 'http://'
    end

    def host_with_port
      @host_with_port ||= 'togodb.dbcls.jp'
    end

    def request_uri
      @request_uri ||= '/togodb'
    end

    private

    def total_records
      return @total_records if @total_records

      @total_records = @src_table.num_records
      @total_records ||= num_records(@src_table.name)
    end

    def num_records_per_copy
      per_copy = total_records / 100

      if per_copy < 10000
        per_copy = 10000
      elsif per_copy > 100000
        per_copy = 100000
      end

      per_copy
    rescue
      10000
    end

  end
end
