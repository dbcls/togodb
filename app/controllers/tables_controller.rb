# coding: utf-8
require 'csv'
require 'json'
require 'fileutils'

class TablesController < ApplicationController
  include Togodb::FileUtils
  include Togodb::StringUtils
  include Togodb::Search
  include Togodb::DatabaseCopier
  include Togodb::Management
  include Togodb::DB::Pgsql
  include ApplicationHelper
  include TablesHelper

  FONT_SIZE = 6

  protect_from_forgery except: %i[show flexigrid fetch info]
  before_action :set_redis
  before_action :set_table, except: %i[index copied_percentage copy_result]
  before_action :read_user_required, only: %i[show download open_search send_uploaded_file]
  before_action :execute_user_required, only: %i[update destroy copy append columns_rdf release]

  def index
    datatables = if @user.superuser?
                   Togodb::DatabaseList::DataTables::AllTables.new(params, @user)
                 else
                   Togodb::DatabaseList::DataTables::PersonalTables.new(params, @user)
                 end

    list_data = datatables.list_data
    list_data[:aaData].each_with_index do |data, i|
      table = TogodbTable.find(data[0])
      data[2] = render_to_string(partial: 'lists/action', locals: { table: table })
      data[0] = render_to_string(partial: 'lists/data_list_url', locals: { table: table })
    end

    callback = params[:callback].blank? ? 'callback' : params[:callback]

    #render json: datatables.list_data.jsonize, callback: callback
    #render json: datatables.list_data.to_json
    render json: list_data.to_json
  end

  # for data list
  def show
    @released_datasets = []
    @writable = allow_write_data?(@user, @table)
    @page_key = "togodb_view_#{random_str(64)}"
    @preview = false

#    if params.key?('--dev--')
#      @dev_mode = true
#      params.delete('--dev--')
#    else
#      @dev_mode = false
#    end
    
    if request.post?
      @preview = true
      @page_body = params[:body]
      @page_head = params[:header]
      @css = params[:css]
      column_attr = parse_column_params
      @redis.set(redis_key_for_column_attr(@page_key), JSON.generate(column_attr))
      add_page_key_to_flexigrid
    end

    respond_to do |format|
      format.html do
        @entry_head_html = entry_page_head_embed_html
        key_value_metastanza = MetaStanza::KeyValue.new(@table)
        @key_value_metastanza_tag = key_value_metastanza.html_tag

        if @preview

        else
          page = TogodbPage.find_by_table_id(@table.id)
          @page_body = page.view_body
          if @page_body.blank?
            @page_body = db_body_default
          end
          @page_head = page.view_header
          if @page_head.blank?
            @page_head = render_to_string(partial: 'pages/view_header_default')
          end

          unless request.query_string == '--dev--'
            if !request.query_string.blank? or params.key?(:search)
              search_condition = save_search_condition(@page_key)
              unless search_condition['condition'].empty?
                add_page_key_to_flexigrid
              end
            end
          end
        end

        register_fs_helper
        template = FlavourSaver::Template.new { @page_body }
        @page_body = template.render
      end

      format.css do
        @page_setting = TogodbPage.find_by_table_id(@table.id)
        if @page_setting
          css = @page_setting.view_css
          if css.blank?
            css = db_css_default
          end
        else
          css = db_css_default
        end
        render plain: css, type: 'text/css'
      end

      format.json do
        metadata_table_json = @table.metastanza_table_json
        if metadata_table_json.blank?
          data_generator = MetaStanza::DataGenerator::PaginationTable.new(@table)
          metadata_table_json = data_generator.generate.to_json
          @table.update(metastanza_table_json: metadata_table_json)
        end

        render json: metadata_table_json
      end

      format.js

      format.ttl do
        db_metadata = TogodbDBMetadata.where(table_id: @table.id).first
        metadata = Togodb::Metadata.new(db_metadata.id)
        render text: metadata.generate_rdf('turtle')
      end

      format.rdf do
        db_metadata = TogodbDBMetadata.where(table_id: @table.id).first
        metadata = Togodb::Metadata.new(db_metadata.id)
        render text: metadata.generate_rdf('rdfxml')
      end
    end
  end

  def update
    begin
      table = TogodbTable.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render text: 'ERROR: No such database.', status: :bad_request
      return
    end

    page_name = table_params[:page_name].to_s.strip
    if page_name.present? && !table.valid_name?(page_name)
      @error_msg = "Alias name '#{page_name}' is used by another user. Please specify another name."
      render
      return
    end

    dl_file_name = table_params[:dl_file_name].to_s.strip
    if dl_file_name.present? && !table.valid_name?(dl_file_name)
      @error_msg = "Download file name '#{dl_file_name}' is used by another user. Please specify another name."
      render
      return
    end

    begin
      change_pkey = false
      orig_page_name = table.page_name
      orig_pkey_column_internal_name = table.pk_column_internal_name

      if params[:togodb_table][:pkey_col_id].blank?
        new_pkey_column_internal_name = 'id'
      else
        new_pkey_column = TogodbColumn.find(params[:togodb_table][:pkey_col_id])
        new_pkey_column_internal_name = new_pkey_column.internal_name
      end

      ActiveRecord::Base.transaction do
        if !orig_pkey_column_internal_name.blank? && !new_pkey_column_internal_name.blank?
          if orig_pkey_column_internal_name != new_pkey_column_internal_name
            change_primary_key(table.name, new_pkey_column_internal_name)
            change_pkey = true
          end
        end

        table.update!(table_params)

        if change_pkey
          if Object.const_defined?(table.class_name)
            Object.class_eval { remove_const table.class_name }
          end
        end
      end
    rescue => e
      js = render_to_string(
          partial: 'set_error_message',
          locals: { element_id: 'db-operation-update-msg', message: e.message }
      )
      render js: js, status: :internal_server_error
    end
  end

  def copy
    if request.post?
      if params.key?(:dst_dbname) && params.key?(:copy_data)
        begin
          @dst_dbname = params[:dst_dbname].strip
          @copy_data = params[:copy_data].to_i == 1
          dst_database_valid?
        rescue InvalidParameter => e
          @message = e.message
          render 'invalid_copy_parameter'
          return
        end

        @authorized_users = if params[:authorized_users]
                              params[:authorized_users]
                            else
                              []
                            end

        @key = copy_database
      end
    else
      @authorized_users = []
      if current_togodb_account.id != @table.creator_id
        @authorized_users << TogodbAccount.find(@table.creator_id)
      end
      TogodbRole.where(table_id: @table.id).each do |role|
        next if role.user_id == @user.id

        @authorized_users << TogodbAccount.find(role.user_id)
      end

      @authorized_users.uniq!
    end
  end

  def copied_percentage
    key = params[:id]

    redis = Resque.redis
    total = redis.get Togodb::DatabaseCopy.total_key(key)
    populated = redis.get Togodb::DatabaseCopy.populated_key(key)

    p = if total.nil? || populated.nil?
          0
        elsif total.to_i.zero?
          100
        else
          ((populated.to_f / total.to_i) * 100).to_i
        end

    render plain: p.to_s, content_type: 'text/plain'
  end

  def copy_result
    key = params[:id]

    redis = Resque.redis
    warning = redis.get Togodb::DatabaseCopy.warning_msg_key(key)
    error = redis.get Togodb::DatabaseCopy.error_msg_key(key)

    if error.blank? && warning.blank?
      @status = 'SUCCESS'
      @message = 'Database copy is completed.'
    elsif error.blank?
      @status = 'WARNING'
      @warning = "WARN: #{warning}"
    else
      @status = 'ERROR'
      @message = "ERROR: #{error}"
    end
  end

  def append
    @create = TogodbCreate.new
    @create.table_id = @table.id
    @create.mode = 'append'
    @create.save!
  end

  def destroy
    @table.delete_database

    flash[:notice] = "The database '#{@table.name}' has been deleted successfully."
  rescue => e
    logger.fatal e.inspect
    logger.fatal e.backtrace.join("\n")
    flash[:error] = "Due to a system error, the database '#{@table.name}' was not deleted."
  ensure
    redirect_to list_path
  end

  def flexigrid
    @preview = params[:preview] == 'true'

    if params[:togodb_view_page_key] && @preview
      ActiveRecord::Base.transaction do
        update_columns_for_preview(params[:togodb_view_page_key])
        set_instance_variables_for_flexigrid
        raise ActiveRecord::Rollback
      end
    else
      set_instance_variables_for_flexigrid
    end

    respond_to do |format|
      @entry_head = entry_page_head_embed_html

      page = TogodbPage.find_by_table_id(@table.id)
      @page_head = page.view_header
      if @page_head.blank?
        @page_head = render_to_string(partial: 'pages/view_header_default')
      end

      format.js
    end
  end

  def fetch
    if allow_read_data?(current_user, @table)
      if params[:preview] == 'true'
        ret_data = flexigrid_empty_data
        ActiveRecord::Base.transaction do
          update_columns_for_preview(params[:togodb_view_page_key])
          ret_data = fetch_for_flexigrid
          raise ActiveRecord::Rollback
        end
      else
        ret_data = fetch_for_flexigrid
      end
    else
      ret_data = flexigrid_empty_data
    end

    callback = params[:callback] ? params[:callback] : 'callback'
    #render :json => ret_data.jsonize, :callback => params[:callback]
    render json: ret_data.to_json, callback: callback
  end

  def info
    respond_to do |format|
      format.js
    end
  end

  def columns_rdf
    elem_id = 'tab-column-rdf-message'
    begin
      ActiveRecord::Base.transaction do
        @table.update!(table_rdf_params)

        params[:togodb_column].to_unsafe_h.keys.each do |id|
          column = TogodbColumn.find(id)
          column.update!(column_rdf_params(id))
        end
      end
      message = 'RDF setting has been updated successfully.'
      render partial: 'set_notice_message', locals: { element_id: elem_id, message: message }
    rescue => e
      message = "ERROR: #{e.message}"
      render partial: 'set_error_message', locals: { element_id: elem_id, message: message }
    end
  end

  def release
=begin
    begin
      db = Togodb::Table.find(table_id)
    rescue
      raise SubmissionFailure, "ERROR: Database not found."
    end

    unless allow_execute?(@user, db)
      raise SubmissionFailure, "ERROR: You don't have permission to release data."
    end
=end
    #begin
    datasets = TogodbDataset.where(table_id: @table.id).order('id')
    messages = []
    datasets.each do |dataset|
      #begin
      Togodb::DataRelease.enqueue_job(dataset.id, update_rdf_repository_after_release?(dataset)) if dataset.can_submit_job?
      #rescue => e
      #  messages << "ERROR: Dataset '#{dataset.name}' could not be released."
      #end
    end

    raise SubmissionFailure, messages.join("\n") unless messages.empty?
    #rescue => e
    #  raise SubmissionFailure, "ERROR: Failed to submit job. Please check the server settings."
    #end
  end

  def download
    send_file_path = generate_csv_for_download
    dl_file_name = @table.dl_file_name.blank? ? @table.name : @table.dl_file_name
    send_file send_file_path, :filename => "#{dl_file_name}.csv", :type => 'text/csv'
  end

  def open_search
    raise Togodb::DatabaseNotFound unless @table

    raise Togodb::AccessDenied unless allow_read_data?(@user, @table)

    #params[:format] ||= 'atom'

    respond_to do |format|
      format.any do
        params[:qtype] ||= 'ALL'
        @query = params[:query]
        @num_records_per_page = 15
        @page = (params[:page] || 1).to_i

        result = exec_open_search(params)
        @num_hits = result[:total]
        @records = result[:records]
        @columns = result[:columns]
        @last_page = last_page

        render formats: [:atom], content_type: 'application/atom+xml'
      end

      format.xml do
        render content_type: 'application/opensearchdescription+xml'
      end
    end
  end

  def send_uploaded_file
    render plain: "#{params[:fpath]}"
  end

  private

  def table_params
    params.require(:togodb_table).permit(
        :name, :enabled, :page_name, :dl_file_name, :sort_col_id, :pkey_col_id
    )
  end

  def table_rdf_params
    params.require(:table).permit(:resource_class, :resource_label)
  end

  def column_rdf_params(id)
    params[:togodb_column].require(id).permit(
        :rdf_p_property_prefix, :rdf_p_property_term, :rdf_p_property,
        :rdf_o_class_prefix, :rdf_o_class_term, :rdf_o_class
    )
  end

  def fetch_for_flexigrid
    @togodb_columns = @table.columns
    search_condition = search_condition_by_param(@table, params.dup)

    page = search_condition[:page]
    offset = search_condition[:offset]
    limit = search_condition[:limit]
    sortname = search_condition[:sortname]
    sortorder = search_condition[:sortorder]
    search_condition_hash_ary = search_condition[:condition]

    result = search_records(@table, search_condition_hash_ary, offset, limit, sortorder, sortname)
    total = result[:total]
    records = result[:records]
    columns = result[:columns]

    ret_data = {}
    ret_data[:page] = page
    ret_data[:total] = total
    ret_data[:rows] = []
    display_webservice_column = @table.webservice_column?
    records.each do |record|
      record_data = {}
      record_data[:id] = record[@table.pk_column_internal_name]
      record_data[:cell] = []

      # TODO サーバ名をrequetヘッダからとれるかどうか
      record_data[:cell] << %Q(<a href="#{@app_server}/entry/#{@table.representative_name}/#{record.id}" target="_blank">Show</a>)
      @all_data = @table.active_record.find(record.id)
      columns.each do |column|
        record_data[:cell] << html_value(record, column)
      end
      if display_webservice_column
        record_data[:cell] << togodb_webservice_column_value(@table, record)
      end
      ret_data[:rows] << record_data
    end

    ret_data
  end

  def flexigrid_empty_data
    {
        page: 1,
        total: 0,
        rows: []
    }
  end

  def estimate_view_table_column_width(table)
    column_width = {}
    records = table.active_record.limit(100).offset(0)
    table.view_show_merged_ordered_columns.each do |column|
      case column.data_type
      when 'integer', 'float', 'numeric', 'double'
        column_width[column.internal_name] = (column.label.length > 5 ? column.label.length * FONT_SIZE : 5 * FONT_SIZE)
      when 'string', 'text'
        max_length = records.map do |r|
          val = r[column.internal_name]
          val.blank? ? 0 : val.length
        end.max
        if max_length >= 40
          column_width[column.internal_name] = 320
        elsif max_length <= column.label.length
          column_width[column.internal_name] = column.label.length * FONT_SIZE
        else
          column_width[column.internal_name] = max_length * FONT_SIZE
        end
      when 'date'
        column_width[column.internal_name] = (column.label.length > 9 ? column.label.length * FONT_SIZE : 9 * FONT_SIZE)
      when 'time'
        column_width[column.internal_name] = (column.label.length > 9 ? column.label.length * FONT_SIZE : 9 * FONT_SIZE)
      when 'datetime'
        column_width[column.internal_name] = (column.label.length > 17 ? column.label.length * FONT_SIZE : 17 * FONT_SIZE)
      when 'timestamp with time zone'
        column_width[column.internal_name] = (column.label.length > 17 ? column.label.length * FONT_SIZE : 17 * FONT_SIZE)
      when 'boolean'
        column_width[column.internal_name] = (column.label.length > 5 ? column.label.length * FONT_SIZE : 5 * FONT_SIZE)
      else
        column_width[column.internal_name] = column.label.length * FONT_SIZE
      end
    end

    column_width
  end

  def login_required?
    case action_name
    when 'show', 'flexigrid', 'fetch'
      false
    else
      true
    end
  end

  def save_search_condition(key)
    search_condition_hash_ary = []
    page = (params[:page] || 1).to_i

    if params[:search].is_a?(ActionController::Parameters) || params[:search].kind_of?(Hash)
      # Advanced search
      h_search = {}
      params[:search].each do |name, value|
        column = Togodb::Column.find_by_name_and_table_id(name, @table.id)
        h_search[column.internal_name.to_sym] = value if column
      end
      search_condition_hash_ary << { type: :advanced, search: h_search }
    elsif params[:search].kind_of?(String)
      # Simple search
      columns = @table.simple_search_columns.select(&:support_text_search?).select do |column|
        if column.text?
          true
        else
          params[:search] =~ /\A\d+\z/
        end
      end.map(&:id)

      search_condition_hash_ary << {
          type: :simple,
          search: params[:search],
          columns: columns
      }
    end

    # Exact match
    colnames = @table.columns.map(&:name)
    h_search = {}
    request.query_parameters.each do |name, value|
      if value.nil?
        pos = name.index(/[=<>]/)
        if pos
          value = name[pos + 1 .. -1]
          ope = name[pos, 1]
          name = name[0 .. pos - 1]
        end
      else
        ope = '='
      end

      if colnames.include?(name)
        column = TogodbColumn.find_by_name_and_table_id(name, @table.id)
        if column
          date_len = 'YYYY-MM-DD'.size
          if column['type'] == 'date' and value.size > date_len
            h_search[column.internal_name + '>'] = value[0, date_len]
            h_search[column.internal_name + '<'] = value[date_len + 1, date_len]
          else
            h_search[column.internal_name + ope] = value
          end
        end
      end
    end

    unless h_search.empty?
      search_condition_hash_ary << { :type => :exact, :search => h_search }
    end

    unless search_condition_hash_ary.empty?
      search_condition = { 'page' => page, 'condition' => search_condition_hash_ary }
      @redis.set redis_key_for_search_condition(key), JSON.generate(search_condition)
      #File.open(search_condition_file_path(key), "w") do |f|
      #  f.write search_condition.jsonize
      #end
    end

    search_condition
  end

  def add_page_key_to_flexigrid
    require 'nokogiri'
    require 'uri'
    doc = Nokogiri("<html><body>#{@page_body}</body></html>")
    doc.search('//script').each do |node|
      next unless node.attributes['src']
      src = node.attributes['src'].value
      if src.kind_of?(String) && src =~ /^\/togodb\/flexigrid\/.+\.js/
        uri = URI.parse(src)
        if uri.query
          node.attributes['src'].value = src + "&togodb_view_page_key=#{@page_key}&preview=#{@preview}"
        else
          node.attributes['src'].value = src + "?togodb_view_page_key=#{@page_key}&preview=#{@preview}"
        end
        break
      end
    end
    @page_body = ''
    doc.root.child.children.each do |child|
      @page_body << child.to_xhtml(encoding: 'UTF-8')
    end
  end

  def exec_open_search(params)
    search_condition_hash_ary = search_condition_hash_ary_by_param(params)
    offset = (@page - 1) * @num_records_per_page
    search_records(@table, search_condition_hash_ary, offset, @num_records_per_page)
  end

  def last_page
    (@num_hits - 1) / @num_records_per_page + 1
  end

  def set_instance_variables_for_flexigrid
    columns = @table.columns

    @buttons = params.key?('buttons')
    @list_columns = @table.list_columns
    @view_show_merged_columns = @table.view_show_merged_ordered_columns
    @search_columns = columns.select(&:action_search).select(&:support_text_search?)

    @width = params[:width].blank? ? 'auto' : params[:width]
    @height = params[:height].blank? ? 400 : params[:height]
    @writable = allow_write_data?(@user, @table)

    @column_width = estimate_view_table_column_width(@table)

    if @width == 'auto'
      @width = "'auto'"
      #@column_width = 150
    else
      #@column_width = (@width.to_i - 50) / @list_columns.size
    end

    @height = "'auto'" if @height == 'auto'

    page = @table.page

    #@quickbrowse_html = render_to_string(partial: 'quickbrowse', format: [ :html ])

    @search_help_lang = nil
    @search_help_lang = page.search_help_lang if page && page.disp_search_help

    @released_datasets = []
  end

  def update_columns_for_preview(key)
    column_attr = @redis.get(redis_key_for_column_attr(key))
    if column_attr
      column_attr = JSON.parse(column_attr)
      column_attr.each do |column_id, attr|
        attr.delete('id_separator_pdl')
        column = TogodbColumn.find(column_id)
        column.update!(attr)
      end
    end
  end

  def register_fs_helper
    prepare_templ_vars.each do |key, value|
      FS.register_helper(key) { value }
    end
  end

  def prepare_templ_vars
    metadata = @table.metadata
    tag_generator = MetaStanza::PaginationTable.new(@table, html_escape: false)

    vars = {
        db_name: @table.name,
        title: metadata&.title,
        description: metadata&.description,
        creator: metadata&.creator,
        togodb_base_url: Togodb.togodb_base_url,
        togostanza_bar_chart_js_tag: %(<script type="module" src="https://togostanza.github.io/metastanza-devel/barchart.js" async></script>),
        togostanza_pie_chart_js_tag: %(<script type="module" src="https://togostanza.github.io/metastanza-devel/piechart.js" assync></script>),
        togostanza_pagination_table_js_tag: %(<script type="module" src="https://togostanza.github.io/metastanza-devel/pagination-table.js" async></script>),
        togostanza_key_value_js_tag: %(<script type="module" src="https://togostanza.github.io/metastanza-devel/key-value.js" async></script>),
        togostanza_pagination_table: tag_generator.html_tag
    }

    @table.columns.each do |column|
      TogodbGraph.where(togodb_column_id: column.id).each do |chart|
        next if chart&.embed_tag.blank?

        # api_url =
        #   "#{Togodb.url_scheme}://#{[Togodb.api_server, 'chart', chart.chart_type, @table.name, column.name].join('/')}.json"
        api_url = chart.api_url
        embed_tag = chart.embed_tag.sub(/(<togostanza\-\w+)(\s+)/) { %(\n#{$1} id="metastanza-#{chart.chart_type}-#{@table.name}-#{column.name}" data-url="#{api_url}"#{$2}) }

        vars["togostanza_#{chart.chart_type}_#{@table.name}_#{column.name}"] = embed_tag
      end
    end

    vars
  end

  def generate_csv_for_download(use_psql_copy = true)
    search_condition = search_condition_by_param(@table, params)
    sortname = search_condition[:sortname]
    sortorder = search_condition[:sortorder]
    search_condition_hash_ary = search_condition[:condition]
    conditions = data_search_conditions(search_condition_hash_ary)

    drs = TogodbDataset.where(table_id: @table.id, name: 'default').first
    columns = if drs
                drs.column_list
              else
                @table.columns
              end
    header_names = columns.map(&:label)
    col_names = columns.map(&:internal_name)

    if use_psql_copy
      generate_selected_record_csv_using_psql_copy(sortname, sortorder, conditions, header_names, col_names)
    else
      generate_selected_record_csv(sortname, sortorder, conditions, header_names, col_names)
    end
  end

  def generate_selected_record_csv(sortname, sortorder, conditions, header_names, col_names)
    csv_file_path = "#{Togodb.tmp_dir}/togodb_dl_#{@table.name}_#{random_str(8)}.csv"
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << header_names
      @table.active_record.select(col_names).where(conditions).order(%Q("#{sortname}" #{sortorder})).each do |record|
        csv << col_names.map{ |col_name| record[col_name] }
      end
    end

    require 'browser'
    browser = Browser.new(request.env['HTTP_USER_AGENT'])
    if browser.platform.windows?
      system "nkf -s -Lw -c --overwrite #{csv_file_path}"
    end

    csv_file_path
  end

  def generate_selected_record_csv_using_psql_copy(sortname, sortorder, conditions, header_names, col_names, use_client_psql = true)
    key = random_str(8)
    csv_file_path = "#{Togodb.tmp_dir}/togodb_dl_#{@table.name}_#{key}.csv"

    if use_client_psql
      sql = @table.active_record.select(col_names).where(conditions).order(%Q("#{sortname}" #{sortorder})).to_sql
      sql_file_path = "#{Togodb.tmp_dir}/togodb_dl_#{@table.name}_#{key}.sql"
      File.open(sql_file_path, 'w') do |f|
        f.puts "\\copy (#{sql}) to '#{csv_file_path}' WITH DELIMITER ',' CSV"
      end
      psql_option = [
          { h: ENV['DATABASE_HOST'] },
          { p: ENV['DATABASE_PORT'] },
          { U: ENV['DATABASE_USER'] },
          { w: nil },
          { f: sql_file_path }
      ].map{ |opt| "-#{opt.keys.at(0)} #{opt[opt.keys.at(0)]}" }.join(' ')

      cmd = %Q(PGPASSWORD=#{ENV['DATABASE_PASSWORD']} #{Togodb.psql_path} #{psql_option} #{ENV["DATABASE_NAME_#{Rails.env.upcase}"]})
      logger.debug cmd

      require 'open3'
      stdout, stderr, status = Open3.capture3(cmd)
      if status.success?
        logger.debug "SQL command of CSV export success."
      else
        logger.debug "SQL command of CSV export failure."
      end
      logger.debug stdout
      logger.debug stderr
    else
      @table.active_record.select(col_names).where(conditions).order(%Q("#{sortname}" #{sortorder})).copy_to(csv_file_path, header: false)
    end

    send_file_path = csv_file_path + '.send'
    CSV.open(send_file_path, 'wb') do |csv|
      csv << header_names
    end

    require 'browser'
    browser = Browser.new(request.env['HTTP_USER_AGENT'])
    if browser.platform.windows?
      system "nkf -s -Lw -c --overwrite #{send_file_path}"
      system "nkf -s -Lw -c #{csv_file_path} >> #{send_file_path}"
    else
      system "cat #{csv_file_path} >> #{send_file_path}"
    end

    send_file_path
  end

end
