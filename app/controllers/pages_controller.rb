class PagesController < ApplicationController
  include Togodb::StringUtils

  before_action :set_table, only: [:show]
  before_action :set_page, except: [:show]
  before_action :read_user_required, except: [:update]
  before_action :execute_user_required, only: %i[show update columns_settings columns_link]

  def show
    #request.headers.sort.map { |k, v| logger.info "#{k}:#{v}" }
    #puts "===== @app_server = #{@app_server} ====="
    # params[:id] is TogoDB Database (PostgreSQL Table) name
    @page = @table.page
    @page.view_css = db_css_default if @page.view_css.blank?
    @page.view_header = db_head_default if @page.view_header.blank?
    @page.view_body = db_body_default if @page.view_body.blank?
    @page.show_css = entry_css_default if @page.show_css.blank?
    @page.show_header = entry_head_default if @page.show_header.blank?
    @page.show_body = entry_body_default if @page.show_body.blank?

    @columns = columns(@table)

    @tables = @user.configurable_tables
    @class_map = ClassMap.where(table_name: @table.name).reorder(id: :desc).first

    @preview_key = "_preview_#{random_str(16)}"

    model = @table.active_record
    record = model.order(:id).first
    @entry_id_value = record.id
  end

  def update
    respond_to do |format|
      @success = @page.update(page_params)
      format.js
    end
  end

  def columns_settings
    elem_id = 'tab-column-basic-message'
    ActiveRecord::Base.transaction do
      params[:togodb_column].to_unsafe_h.keys.each do |id|
        column = TogodbColumn.find(id)
        column.update!(columns_settings_params(id))
      end
    end
  rescue => e
    logger.fatal e.inspect
    logger.fatal e.backtrace.join("\n")
    message = "ERROR: #{e.message}"
    render partial: 'set_error_message', locals: { element_id: elem_id, message: message }
  end

  def columns_link
    @columns = columns(@table)
    elem_id = 'tab-column-link-message'

    ActiveRecord::Base.transaction do
      params[:togodb_column].to_unsafe_h.keys.each do |id|
        column = TogodbColumn.find(id)
        text_search_supported = column.support_text_search?
        column.update!(columns_link_params(id))
        if !text_search_supported && column.support_text_search?
          column.action_search = true
          column.save!
        end
      end
    end
  rescue => e
    logger.fatal e.inspect
    logger.fatal e.backtrace.join("\n")
    message = "ERROR: #{e.message}"
    render partial: 'set_error_message', locals: { element_id: elem_id, message: message }
  end

  def view_css_default
    render plain: db_css_default, content_type: 'text/css'
  end

  def view_header_default
    render plain: db_head_default, content_type: 'text/html'
  end

  def view_body_default
    render plain: db_body_default, content_type: 'text/html'
  end

  def show_css_default
    render plain: entry_css_default, content_type: 'text/css'
  end

  def show_header_default
    render plain: entry_head_default, content_type: 'text/html'
  end

  def show_body_default
    render plain: entry_body_default, content_type: 'text/html'
  end

  def quickbrowse_default
    set_columns
    respond_to do |format|
      format.js
    end
  end

  private

  def set_page
    @page = TogodbPage.find(params[:id])
    @table = TogodbTable.find(@page.table_id)
  end

  def permit_params
    %i[
      header_line
      view_css view_header view_body
      show_css show_header show_body
      quickbrowse
    ]
  end

  def page_params
    if params[:togodb_page]
      params.require(:togodb_page).permit(permit_params)
    elsif params[:page]
      params.require(:page).permit(permit_params)
    end
  end

  def columns_settings_params(id)
    params[:togodb_column].require(id).permit(
        :num_decimal_places, :label, :action_list, :sanitize, :comment, :action_search, :action_luxury
    )
  end

  def columns_link_params(id)
    params[:togodb_column].require(id).permit(
        :id_separator, :other_type, :html_link_prefix
    )
  end

end
