require 'togo_mapper/d2rq'

class ApplicationController < ActionController::Base
  include Togodb::Management

  protect_from_forgery with: :exception

  before_action :set_user
  before_action :app_server

  class UnauthorizedAccess < StandardError
  end

  rescue_from UnauthorizedAccess, with: :unauthorized_access

  private

  def unauthorized_access
    head :not_found
  end

  def render_notice_message(msg_item_id, message)
    render partial: 'set_notice_message', locals: { element_id: msg_item_id, message: message }
  end

  def render_error_message(msg_item_id, message)
    render partial: 'set_error_message', locals: { element_id: msg_item_id, message: message }
  end

  def set_user
    @user = current_user
    @tables = @user&.configurable_tables
  end

  def app_server
    @app_server = "#{request.scheme}://#{ENV.fetch('SERVER_NAME')}"
    #@app_server = "#{request.scheme}://#{request.headers['HTTP_X_FORWARDED_HOST']}"
    #@app_server = request.headers['HTTP_ORIGIN'].to_s
  end

  def current_user
    TogodbUser.find(session[login_user_session_key])
  rescue
    nil
  end

  def set_current_user(user_id)
    session[login_user_session_key] = user_id
  end

  def read_user_required
    if @table && !@table.enabled && !allow_read_data?(@user, @table)
      raise UnauthorizedAccess
    end
  end

  def write_user_required
    raise UnauthorizedAccess if @user.nil? || !allow_write_data?(@user, @table)
  end

  def execute_user_required
    raise UnauthorizedAccess if @user.nil? || !allow_execute?(@user, @table)
  end

  def login_required?
    if @table
      !@table.enabled
    else
      true
    end
  end

  def require_login
    redirect_to_login unless logged_in?
  end

  def logged_in?
    !@user.nil?
  end

  def redirect_to_login
    redirect_to login_url
  end

  def set_table
    if params[:table_id]
      @table = TogodbTable.find(params[:table_id])
    else
      if /\A\d+\z/ =~ params[:id]
        @table = TogodbTable.find(params[:id])
      else
        @table = TogodbTable.find_by(page_name: params[:id])
        @table = TogodbTable.find_by(name: params[:id]) if @table.nil?
      end
    end

    raise ActiveRecord::RecordNotFound if @table.nil?
  end

  def set_roles(table)
    @roles = TogodbRole.where(table_id: table.id).includes(:user).order(:id)
  end

  def set_datasets
    set_dataset_select_opts
    unless @togodb_dataset
      @togodb_dataset = @datasets[0]
      @togodb_dataset = TogodbDataset.new(table_id: @table.id) unless @togodb_dataset
    end
    set_dataset_columns

    @filter_condition = if @togodb_dataset.filter_condition.blank?
                          {}
                        else
                          JSON.parse(@togodb_dataset.filter_condition)
                        end
  end

  def set_dataset_select_opts
    @datasets = TogodbDataset.where(table_id: @table.id).order('id')
    @select_opts = []
    @datasets.each do |dataset|
      @select_opts << [dataset.id, dataset.name]
    end
  end

  def set_dataset_columns
    included_column_ids = @togodb_dataset.columns.split(',').map(&:to_i)
    @included_columns = []
    @omitted_columns = []
    @table.enabled_columns.each do |column|
      index = included_column_ids.index(column.id)
      if index
        @included_columns[index] = column
      else
        @omitted_columns << column
      end
    end
  rescue
    @included_columns = []
    @omitted_columns = []
  end

  def set_redis
    @redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
  end

  def update_rdf_repository_after_release?(dataset)
    Togodb.use_owlim && Togodb.create_new_repository && @togodb_dataset.update_rdf_repository?
  end

  def columns(table)
    TogodbColumn.where(table_id: table.id, enabled: true).order('list_disp_order')
  end

  def login_user_session_key
    'togodb_v4.user_id'
  end

  def parse_column_params
    columns_settings = params[:columns_settings]
    columns_link = params[:columns_link]

    model_attr = {}
    columns_settings.to_unsafe_h.keys.each do |k|
      h = columns_settings[k]
      next unless h['name'] =~ /\Atogodb_column\[(\d+)\]\[(.+)\]\z/

      column_id = $1
      column_name = $2
      model_attr[column_id] = {} unless model_attr.key?(column_id)
      model_attr[column_id][column_name] = h['value']
    end

    columns_link.to_unsafe_h.keys.each do |k|
      h = columns_link[k]
      next unless h['name'] =~ /\Atogodb_column\[(\d+)\]\[(.+)\]\z/

      column_id = $1
      column_name = $2
      model_attr[column_id] = {} unless model_attr.key?(column_id)
      model_attr[column_id][column_name] = h['value']
    end

    model_attr
  end

  def redis_key_for_column_attr(key)
    "togodb:#{key}:column_attr"
  end

  def entry_page_head_embed_html
    html = @table.page.show_header
    html = render_to_string(partial: 'pages/show_header_default') if html.blank?

    html
  end

  def create_page
    TogodbPage.create!(
        table_id: @table.id,
        view_css: db_css_default,
        view_header: db_head_default,
        view_body: db_body_default,
        quickbrowse: entry_body_default,
        show_css: entry_css_default,
        show_header: entry_head_default,
        show_body: entry_body_default
    )
  end

  def db_css_default
    File.read(Rails.root.join('config', 'page_default', 'db.css').to_path)
  end

  def db_head_default
    Slim::Engine.with_options(pretty: true) do
      render_to_string(partial: 'pages/view_header_default')
    end
  end

  def db_body_default
    Slim::Engine.with_options(pretty: true) do
      render_to_string(partial: 'pages/view_body_default')
    end
  end

  def entry_css_default
    if %w[semantic v3].include?(@table.migrate_ver) && !@table.page.show_body.blank?
      File.read(Rails.root.join('config', 'page_default', 'v3_entry.css').to_path)
    else
      File.read(Rails.root.join('config', 'page_default', 'entry.css').to_path)
    end
  rescue
    File.read(Rails.root.join('config', 'page_default', 'entry.css').to_path)
  end

  def entry_head_default
    Slim::Engine.with_options(pretty: true) do
      render_to_string(partial: 'pages/show_header_default')
    end
  end

  def entry_body_default
    set_position_ordered_columns
    Slim::Engine.with_options(pretty: true) do
      render_to_string(partial: 'pages/show_body_default')
    end
  end

  def set_position_ordered_columns
    @columns = TogodbColumn.where(table_id: @table.id).order(:position)
  end

end
