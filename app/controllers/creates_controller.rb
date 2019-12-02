class CreatesController < ApplicationController
  include Togodb::DatabaseCreator

  before_action :require_login
  before_action :set_create, except: %i[new create]

  def new
    @create = TogodbCreate.new
    @create.mode = 'create'
  end

  def create
    name = params[:table_name].to_s.strip
    begin
      check_database_name(name)

      ActiveRecord::Base.transaction do
        @table = TogodbTable.new(name: name)
        @table.enabled = false
        @table.creator_id = @user.id
        @table.save!

        @create = TogodbCreate.new
        @create.table_id = @table.id
        @create.user_id = @user.id
        @create.mode = 'create'
        @create.save!
      end
    rescue => e
      logger.fatal e.inspect
      logger.fatal e.backtrace.join("\n")
      @message = e.message
    end
  end

  def upload
    @truncated_head_records = []

    if request.get?
      set_records
    elsif request.post?
      begin
        if params[:mode]
          @create.mode = params[:mode]
          @create.save!
        end

        handle_upload

        set_records if params[:method] == 'upload'
      rescue CSV::MalformedCSVError => e
        @upload_message = "#{@create.file_format.to_s.upcase} file format error: #{e.message}"
        render 'retry_upload'
      rescue => e
        logger.fatal e.inspect
        logger.fatal e.backtrace.join("\n")
        @error_message = 'Internal server error.'
        render 'cannot_continue'
      end
    end
  end

  def header
    if request.get?
      records = parse_for_header_line
      @truncated_head_records = []
      records.each do |record|
        @truncated_head_records << record.map { |s| multibyte_truncate(s, 50) }
      end
    elsif request.post?
      begin
        ActiveRecord::Base.transaction do
          @create.header_line = params[:header]
          @column_samples = column_name_and_sample_by_file(params[:header] == 't')
          @create.sample_data = @column_samples.to_json
          @create.num_columns = @column_samples.size
          @create.save!

          case @create.mode
          when 'create'
            @columns = create_columns
            create_page
            Togodb::DataRelease.create_default_dataset(@table.id)
          when 'append'
            column_names = JSON.parse(@create.sample_data).map { |data| data['name'] }
          when 'overwrite'
            @create.table.drop_table
            @create.table.create_table
          end
        end

        respond_to do |format|
          format.js do
            if @create.mode == 'create'
              render 'columns'
            else
              @key = enqueue_data_import_job
              render 'import'
            end
          end
        end
      rescue => e
        case e
        when CSV::MalformedCSVError
          @error_message = e.message
        else
          @error_message = 'Internal server error.'
        end
        @table.destroy!
        render 'cannot_continue'
      end
    end
  end

  def columns
    return unless request.post?

    params[:column].to_unsafe_h.keys.each do |id|
      column = TogodbColumn.find(id)

      col_attr = column_params(id)
      column.update!(col_attr)
      column.internal_name = "#{Togodb::COLUMN_PREFIX}#{col_attr['name']}"
      column.save!
    end

    @table.create_table
    @key = enqueue_data_import_job

    render 'import'
  end

  def progress(klass = Togodb::DataImporter)
    klass = Togodb::DataDownloader if params[:uptype].to_s == 'data_download'

    key = params[:key]
    redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
    populated = redis.get(klass.populated_key(key))
    warning = redis.get(klass.warning_msg_key(key))
    error = redis.get(klass.error_msg_key(key))

    if populated == 100
      #write_map_resource_file(table.name.pluralize)
    end

    if params[:uptype] == 'data_download'
      render json: { pct: populated, warning: warning.to_s, error: error.to_s }.to_json
    else
      render plain: populated
    end
  end

  def status
    klass = Togodb::DataImporter
    key = params[:key]

    redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
    warning = redis.get(klass.warning_msg_key(key))
    error = redis.get(klass.error_msg_key(key))

    if error.blank? && warning.blank?
      result = {
          status: 'SUCCESS',
          message: %Q|Data import has been successfully completed.|
      }
    elsif error.blank?
      result = {
          status: 'WARNING',
          message: %Q|#{warning}&nbsp;&nbsp;<a id="togodb-create-go-config-btn" href="#{config_path(@table.name)}">Config</a>|
      }
    else
      result = { status: 'ERROR', message: error }
    end

    render json: result.to_json
  end

  def populated_percentage(key, klass = Togodb::DataImporter)
    redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
    populated = redis.get klass.populated_key(key)
    warning = redis.get klass.warning_msg_key(key)
    error = redis.get klass.error_msg_key(key)

    { pct: populated, warning: warning.to_s, error: error.to_s }
  end

  def convert_progress
    populated = populated_percentage(params[:key], Togodb::DataDownloader)
    if populated[:pct] == '200'
      progress = 100
    else
      upload_size = File.size(@create.uploded_file_path)
      convert_size = File.size(@create.utf8_file_path)

      progress = ((convert_size.to_f / upload_size) * 90).to_i
      progress = 99 if progress >= 100
    end

    render json: { pct: progress.to_s }.to_json
  end

  private

  def set_create
    @create = TogodbCreate.find(params[:id])
    @table = TogodbTable.find(@create.table_id)
  end

  def column_params(id)
    params[:column].require(id).permit(
        :name, :label, :data_type, :enabled, :num_integer_digits, :num_fractional_digits
    )
  end

  def handle_upload
    file = params[:file]
    if file.is_a?(ActionDispatch::Http::UploadedFile)
      tempfile_path = file.tempfile.path
    end

    file_format = params[:file_format]
    output_file = uploaded_file(params[:file_format])
    converted_file = utf8_file(params[:file_format])

    begin
      @create.uploded_file_path = output_file
      @create.utf8_file_path = converted_file
      @create.file_format = file_format
      @create.save!

      if params[:remote_url]
        @key = random_str
        redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
        redis.set Togodb::DataDownloader.populated_key(@key), '0'
        Resque.enqueue Togodb::DataDownloadJob, @create.id, params[:remote_url], @key
      else
        case file
        when ActionDispatch::Http::UploadedFile
          copy_file(tempfile_path, output_file)
        when String
          File.open(output_file, 'wb') do |f|
            f.write request.body.read
          end
        end
        convert_to_utf8(output_file, converted_file)
      end
    rescue => e
      logger.fatal e.inspect
      logger.fatal e.backtrace.join("\n")
      @message = e.message
    end
  end

  def set_records
    records = parse_for_header_line
    records.each do |record|
      @truncated_head_records << record.map { |s| multibyte_truncate(s, 50) }
    end
  end
end
