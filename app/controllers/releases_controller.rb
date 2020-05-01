class ReleasesController < ApplicationController
  include Togodb::Management

  before_action :require_login, except: [:download]
  before_action :set_table, only: [:redraw]
  before_action :set_table_for_dl, only: [:download]
  before_action :set_dataset, only: %i[run]
  before_action :read_user_required, only: [:download]

  def index
    @tables = @user.configurable_tables
  end

  def show
    @table = TogodbTable.where(name: params[:id]).first
    @datasets = TogodbDataset.where(table_id: @table.id).order(:id)
    @columns = columns(@table)

    @tables = @user.configurable_tables
    @class_map = ClassMap.where(table_name: @table.name).reorder(id: :desc).first
  end

  def list
    release = Togodb::Release.new(current_user, params)

    render json: release.list_data.to_json
  end

  def redraw
    set_datasets
  end

  def download
    prepare_download

    send_file @dl_file_path, filename: download_filename, type: @content_type
  end

  def run
    Togodb::DataRelease.enqueue_job(@togodb_dataset.id, update_rdf_repository_after_release?(@togodb_dataset))
  end

  private

  def set_dataset
    @togodb_dataset = TogodbDataset.find(params[:id])
  end

  def set_table_for_dl
    @table = TogodbTable.find_by(dl_file_name: params[:id])
    set_table if @table.nil?
  end

  def prepare_download
    case params[:format]
    when 'csv'
      @content_type = 'text/csv'
    when 'json'
      @content_type = 'application/json'
    when 'rdf'
      @content_type = 'application/rdf+xml'
    when 'ttl'
      @content_type = 'text/turtle'
    else
      @content_type = 'text/plain'
    end

    @dl_file_path = "#{Togodb.dataset_dir}/#{released_filename}"

    unless File.exist?(@dl_file_path)
      raise Togodb::FileNotFound, "No such file '#{params[:id]}.#{params[:format]}'."
    end
  end

  def released_filename
    if @dataset_name
      "#{@table.name}_#{@dataset_name}.#{params[:format]}"
    else
      "#{@table.name}_default.#{params[:format]}"
    end
  end

  def download_filename
    base_name = @table.dl_file_name.blank? ? @table.name : @table.dl_file_name

    if @dataset_name
      "#{base_name}-#{@dataset_name}.#{params[:format]}"
    else
      "#{base_name}.#{params[:format]}"
    end
  end

end
