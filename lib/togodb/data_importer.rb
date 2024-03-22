require 'csv'
require 'redis'
require 'resque'
require 'yaml'
require 'logger'

class Togodb::DataImporter
  include Togodb::DB::Pgsql
  include Togodb::StringUtils
  include D2RQMapper

  UPLOAD_FILES_DIR = File.join(ENV.fetch('DATA_DIR'), 'upload_files')

  class TooManyListValues < StandardError;
  end

  class << self
    def total_key(key)
      "data_import_#{key}_total"
    end

    def populated_key(key)
      "data_import_#{key}_populated"
    end

    def warning_msg_key(key)
      "data_import_#{key}_warning"
    end

    def error_msg_key(key)
      "data_import_#{key}_error"
    end
  end


  def initialize(create_id, key, csv_cols)
    @create = TogodbCreate.find(create_id)
    @key = key
    @csv_cols = csv_cols
    @num_enabled_columns = @csv_cols.select { |column| column['enabled'] }.size

    @table = TogodbTable.find(@create.table_id)
    @user_id = @create.user_id
    @has_header = @create.header_line

    @data_file = File.join(UPLOAD_FILES_DIR, File.basename(@create.uploded_file_path))
    @file_size = File.size(@data_file)

    @entry_id = 1
    @metastanza_json_generator = MetaStanza::DataGenerator::PaginationTable.new(@table)
    @metadata_table_rows = []

    begin
      @time_zone = Rails.application.config.time_zone
    rescue
      @time_zone = 'UTC'
    end

    @warn_msgs = []
    @redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)

    @log = Logger.new("#{Rails.root}/log/data-importer-#{@create.id}.log", level: :debug)
    @log.formatter = proc { |severity, datetime, progname, message|
      "#{severity}\t#{datetime}: #{message}\n"
    }

    @log.info %/Togodb::DataImporter.new(#{create_id}, #{key}, #{csv_cols})/
  end

  def import
    num_records = 0
    populated_size = 0
    cur_percentage = 0
    base_time = Time.now

    begin
      conn = connect
      conn.exec('BEGIN')

      prepare_insert(conn)

      CSV.foreach(@data_file, **csv_opts) do |record|
        record = record.map { |ary| ary[1] } if record.kind_of?(CSV::Row)

        next if empty_line?(record)

        insert_record(conn, record)
        num_records += 1

        populated_size += record_size(record)

        if Time.now - base_time > 1 && cur_percentage < 99
          percentage = ((populated_size.to_f / @file_size) * 100).to_i
          percentage = 99 if percentage >= 100
          if percentage > cur_percentage
            @redis.set populated_key, percentage
            cur_percentage = percentage
          end
          base_time = Time.now
        end

        @entry_id += 1
      end

      update_togodb_table(conn, num_records)
      insert_togodb_page(conn)
      refresh_list_column_values_all(conn)

      setup_new_mapping_for_togodb(@table.name, @table.creator_id)

      insert_metastanza_table_json(conn)

      def_ds_id = default_dataset_id(conn)
      @log.debug "import: default_dataset_id: #{def_ds_id}"

      conn.exec('COMMIT')
      @redis.set populated_key, 100

      create_indexes(conn)

      Togodb::DataRelease.enqueue_job(def_ds_id, Togodb.create_new_repository) if Togodb.create_release_files
    rescue => e
      conn&.exec('ROLLBACK')
      @redis.set error_msg_key, "#$!"
      @log.fatal %(#{e.message}\n#{e.backtrace.join("\n")})
      raise e
    ensure
      conn&.close
      @redis.set warning_msg_key, @warn_msgs.join('<br />') unless @warn_msgs.empty?
      @redis.set populated_key, 100
    end
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

  private

  def connect
    db_config = Togodb.database_configuration
    PG.connect(host: db_config[:host], port: db_config[:port], dbname: db_config[:database],
               user: db_config[:username], password: db_config[:password])
  end

  def prepare_insert(conn)
    @stmt_id = @table.name
    stmt = %/INSERT INTO "#{@table.name}" (#{columns_for_insert}) VALUES (#{values_stmt_for_insert})/
    @log.debug stmt
    conn.prepare(@stmt_id, stmt)
  end

  def columns_for_insert
    @csv_cols.select { |c| c['enabled'] }.map { |c| %("#{c['internal_name']}") }.join(',')
  end

  def values_stmt_for_insert
    @num_enabled_columns.times.map { |i| "$#{i + 1}" }.join(',')
  end

  def insert_record(conn, record)
    column_names = []
    values = []
    record.each_with_index do |data, i|
      column = @csv_cols[i] or next
      next unless column['enabled']

      case column['data_type']
      when 'string', 'text'
      else
        data = nil if data.blank?
      end
      column_names << column['internal_name']
      values << data
    end
    num_difference = @num_enabled_columns - values.size
    values = values + Array.new(num_difference) if num_difference.positive?

    insert(conn, values)

    column_names.unshift('id')
    values.unshift(@entry_id)
    @metadata_table_rows << metastanza_table_row_hash(column_names.zip(values).to_h)
  end

  def insert(conn, values)
    @log.debug 'insert: ' + @stmt_id + ':' + values.to_s
    conn.exec_prepared(@stmt_id, values)
  end

  def delete_all_records(conn)
    sql = "DELETE FROM #{@table.name}"
    @log.debug sql
    conn.exec(sql)
  end

  def refresh_list_column_values_all(conn)
    stmt_id = "#{@table.name}_insert_list_values"
    stmt = %/INSERT INTO togodb_column_values (column_id,value) VALUES ($1,$2)/
    @log.debug stmt
    conn.prepare(stmt_id, stmt)

    sql = "SELECT id,name,internal_name FROM togodb_columns WHERE table_id=#{@table.id} AND other_type='list'"
    @log.debug sql
    result = conn.exec(sql)
    result.each do |r|
      refresh_list_column_values_one(conn, stmt_id, { id: r['id'].to_i, name: r['name'], internal_name: r['internal_name'] })
    end
  end

  def refresh_list_column_values_one(conn, stmt_id, column)
    delete_list_values(conn, column)
    insert_list_values(conn, stmt_id, column)
  end

  def delete_list_values(conn, column)
    sql = "DELETE FROM togodb_column_values WHERE column_id=#{column[:id]}"
    @log.debug sql
    conn.exec(sql)
  end

  def insert_list_values(conn, stmt_id, column)
    list_column_values(conn, column).each do |v|
      next if v.to_s.strip == ''

      @log.debug "#{stmt_id}:[#{column[:id]},#{v}]"
      conn.exec_prepared(stmt_id, [column[:id], v])
    end
  rescue TooManyListValues => e
    @warn_msgs << e.message
    reset_column_other_type(conn, column)
  end

  def list_column_values(conn, column)
    values = []
    sql = %(SELECT DISTINCT "#{column[:internal_name]}" FROM "#{@table.name}" ORDER BY "#{column[:internal_name]}")
    @log.debug sql
    result = conn.exec(sql)
    num_values = result.ntuples
    if num_values > 1000
      raise TooManyListValues, "WARNING: Column \"#{column[:name]}\": The number of values is #{num_values}. List type setting has been disabled."
    else
      result.values.map { |ary| ary[0] }
    end
  end

  def reset_column_other_type(conn, column)
    sql = "UPDATE togodb_columns SET other_type=NULL WHERE id=#{column[:id]}"
    @log.debug sql
    conn.exec(sql)
  end

  def init_sequence(conn)
    pkey_infos = primary_key_infos(@table.name)
    pkey_colnames = pkey_infos.map { |p| p[:columnname] }
    if !pkey_infos.empty? && pkey_infos[0][:column_name] == 'id'
      sql = %/SELECT setval('#{sequence_name(@table.name, 'id')}', 1, FALSE)/
      @log.debug sql
      conn.exec(sql)
    end
  end

  def get_num_records(conn)
    sql = %(SELECT num_records FROM togodb_tables WHERE id=#{@table.id})
    @log.debug sql
    result = conn.exec(sql)
    result[0]['num_records'].to_i
  end

  def update_togodb_table(conn, num_inserted)
    cur_num = if @create.mode == 'append'
                get_num_records(conn)
              else
                0
              end
    sql = %(UPDATE "togodb_tables" SET "num_records"=#{cur_num + num_inserted}, "updated_at"=#{cur_timestamp_for_sql} WHERE "id"=#{@table.id})
    @log.debug sql
    conn.exec(sql)
  end

  def insert_togodb_page(conn)
    sql = %(SELECT "id" FROM "togodb_pages" WHERE "table_id"=#{@table.id})
    @log.debug sql
    result = conn.exec(sql)
    if result.ntuples.zero?
      sql = %/INSERT INTO "togodb_pages" ("table_id","created_at","updated_at") VALUES (#{@table.id},#{cur_timestamp_for_sql},#{cur_timestamp_for_sql})/
      @log.debug sql
      conn.exec(sql)
    end
  end

  def cur_timestamp_for_sql
    '(CURRENT_TIMESTAMP)'
  end

  def csv_opts
    fs = ','
    fs = "\t" if @data_file[-3 .. -1] == 'tsv'

    {
      encoding: "#{@create.input_file_encoding}:UTF-8",
      col_sep: fs,
      headers: @has_header,
      return_headers: false,
      liberal_parsing: true
    }
  end

  def empty_line?(record)
    record.each do |data|
      return false if data.to_s.strip != ''
    end

    true
  end

  def record_size(record)
    size = 0
    record.each do |value|
      size += value.to_s.size
    end

    size += record.size

    size
  end

  def default_dataset_id(conn)
    sql = "SELECT id FROM togodb_datasets WHERE table_id=#{@table.id} AND name='default'"
    @log.debug sql
    result = conn.exec(sql)
    id = if result.ntuples.zero?
           insert_default_dataset(conn)
         else
           result[0]['id'].to_i
         end

    id
  end

  def insert_default_dataset(conn)
    sql = "SELECT id FROM togodb_columns WHERE table_id=#{@table.id} AND enabled='t' ORDER BY position"
    @log.debug sql
    result = conn.exec(sql)
    column_ids = result.values.map { |ary| ary[0] }.join(',')

    sql = "INSERT INTO togodb_datasets (table_id,name,columns,created_at,updated_at) VALUES (#{@table.id},'default','#{column_ids}',#{cur_timestamp_for_sql},#{cur_timestamp_for_sql}) RETURNING id"
    @log.debug sql
    result = conn.exec(sql)

    result[0]['id']
  end

  def create_indexes(conn)
    conn.exec('CREATE EXTENSION IF NOT EXISTS pg_trgm')
    idx_names = index_names(conn)
    @table.columns.each do |column|
      if idx_names.include?(index_name(@table.name, column.internal_name)) || idx_names.include?(index_name(@table.name, column.internal_name, 'gin'))
        next
      end

      if column.data_type == 'text'
        unless idx_names.include?(index_name(@table.name, column.internal_name, 'gin'))
          create_gin_index(@table.name, column.internal_name, conn)
        end
      else
        create_btree_index(@table.name, column.internal_name, conn)
      end
    end
  end

  def insert_metastanza_table_json(conn)
    puts @metadata_table_rows.to_json
    stmt_id = "#{@table.name}_insert_metastanza_table_json"
    stmt = 'UPDATE togodb_tables SET metastanza_table_json = $1 WHERE id = $2'
    @log.debug stmt
    conn.prepare(stmt_id, stmt)
    conn.exec_prepared(stmt_id, [@metadata_table_rows.to_json, @table.id])
  end

  def metastanza_table_row_hash(row)
    row_hash =
      @metastanza_json_generator.show_link_hash(@table)

    @table.columns.where(enabled: true).each do |togodb_column|
      row_hash.merge!(
        @metastanza_json_generator.hash_for_column_data(row, togodb_column)
      )
    end

    row_hash
  end
end
