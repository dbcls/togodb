require 'fileutils'
require 'zip'

class SupplementaryFilesController < ApplicationController
  include Togodb::FileUtils

  # Since @table instance is used by *_user_required, set_table and set_supplementary_file is called before *_user_required.
  before_action :set_table, only: %i[show create send_supplementary_file]
  before_action :set_supplementary_file, only: %i[update destroy]

  before_action :read_user_required, only: %i[show send_supplementary_file]
  before_action :execute_user_required, only: %i[show create destroy]

  protect_from_forgery except: :send_supplementary_file

  class NoZipFileUploaded < StandardError; end

  def show
    @supplementary_file = TogodbSupplementaryFile.where(togodb_table_id: @table.id).order('id DESC').first
    if @supplementary_file.nil?
      @supplementary_file = TogodbSupplementaryFile.new
    elsif @supplementary_file.exist_zip_file?
      @tree_json_data = @supplementary_file.tree_json
    end
  end

  def create
    handle_uploaded_file
  end

  def update
    handle_uploaded_file
  end

  def destroy
    @supplementary_file.destroy!

    redirect_to upload_files_url(@table.name)
  end

  def send_supplementary_file
    if params[:fpath].to_s.index('..')
      head :not_found
      return
    end

    supplementary_file = supplementary_file_by_table(@table)
    file_path = supplementary_file.file_path_by_url_path(params[:fpath])
    logger.debug "Local path of supplementary_file: #{file_path}"
    unless file_path.exist?
      head :not_found
      return
    end

    send_file file_path.to_path, disposition: 'inline'
  end

  private

  def set_supplementary_file
    @supplementary_file = TogodbSupplementaryFile.find(params[:id])
    @table = @supplementary_file.table
  end

  def supplementary_file_by_table(table)
    TogodbSupplementaryFile.where(togodb_table_id: table.id).order('id DESC').first
  end

  def handle_uploaded_file
    TogodbSupplementaryFile.transaction do
      uploaded_file = params[:supplementary_file]
      raise NoZipFileUploaded if uploaded_file.nil?

      unless @supplementary_file
        @supplementary_file = TogodbSupplementaryFile.create!(
            togodb_table_id: @table.id,
            original_filename: uploaded_file.original_filename
        )
      end

      # Save uploaded file
      File.open(uploaded_file_save_path, 'w+b') do |f|
        f.write uploaded_file.read
      end

      # Extract uploaded zip file
      FileUtils.rm_r(zip_extract_dir_path, secure: true) if File.exist?(zip_extract_dir_path)
      Dir.mkdir(zip_extract_dir_path)
      zip_handler = Togodb::ZipHandler.new
      zip_handler.unzip(uploaded_file_save_path, zip_extract_dir_path)

      # Since the new files were saved, delete the old files and move new file
      @supplementary_file.update!(
          original_filename: uploaded_file.original_filename
      )
      @supplementary_file.move_files(uploaded_file_save_path, zip_extract_dir_path)
    end
  rescue NoZipFileUploaded
    flash[:err] = 'No zip file selected.'
  rescue Zip::Error => e
    flash[:err] = e.message
  rescue Zip::CompressionMethodError => e
    flash[:err] = e.message
  rescue => e
    logger.fatal e.inspect
    logger.fatal e.backtrace.join("\n")
    flash[:err] = 'Sorry, system error has occurred.'
  ensure
    redirect_to upload_files_url(@table.name)
  end

  def uploaded_file_save_path
    "#{Togodb.upfile_saved_dir}/supplementary_file#{@table.id}.zip"
  end

  def zip_extract_dir_path
    "#{Togodb.upfile_saved_dir}/supplementary_file#{@table.id}"
  end

end
