class EntriesController < ApplicationController
  include Togodb::Management
  include ApplicationHelper
  include TablesHelper
  include EntriesHelper
  include MetaStanza::MixIn

  before_action :set_table
  before_action :read_user_required, only: %i[show form quickbrowse quickbrowse_edit_form]
  before_action :execute_user_required, only: %i[create update destroy]

  def show
    if request.post?
      @preview = true
      @css = params[:css]

      if params[:format].blank?
        ActiveRecord::Base.transaction do
          preview_html
          raise ActiveRecord::Rollback
        end

        return
      end
    end

    @columns = @table.columns
    if params[:format].blank? || params[:format] != 'css'
      if params[:id]
        @id = params[:id]
        @record = @table.active_record.find(@id)
      else
        pk_column_name = TogodbTable.actual_primary_key(@table.name)
        @record = @table.active_record.order(pk_column_name).first
        @id = @record[pk_column_name]
      end
      @record_name = record_name(@table, @record)
    end

    set_page_setting(@table)

    respond_to do |format|
      format.html {
        register_fs_helper(@id)
        @page_head = page_head_html
        @page_body = page_body_html
      }

      format.json {
        # data = hash_for_json
        data = array_for_key_value_metastanza
        if params[:callback]
          render json: JSON.generate(data), callback: params[:callback]
        else
          render json: JSON.pretty_generate(data)
        end
      }

      format.rdf {
        exporter = Togodb::Exporter::RDF.new(@table, @columns, Togodb.temporary_workspace, 'rdf')
        exporter.export_rdf([@record])
        render plain: exporter.output, content_type: "application/rdf+xml"
      }

      format.ttl {
        exporter = Togodb::Exporter::RDF.new(@table, @columns, Togodb.temporary_workspace, 'ttl')
        exporter.export_ttl([@record])
        render plain: exporter.output, content_type: "text/turtle; charset=utf-8"
      }

      format.css {
        content_type = 'text/css'
        if @preview
          render css: params[:css]
        else
          if @page_setting
            css = @page_setting.show_css
            if css.blank?
              render(plain: entry_css_default, content_type:)
            else
              render plain: css, content_type:
            end
          else
            render plain: entry_css_default, content_type:
          end
        end
      }

      format.js
    end
  end

  def form
    @record = if params[:id]
                @table.active_record.find(params[:id])
              else
                @table.active_record.new
              end
  end

  def quickbrowse
    if false
      @record = @table.active_record.find(params[:id])
      @columns = @table.columns

      quickbrowse_html = @table.page.show_body
      quickbrowse_html = entry_body_default if quickbrowse_html.blank?

      register_fs_helper(@record.id)
      template = FlavourSaver::Template.new { prepare_template quickbrowse_html }
      @html = template.render

      @src = "#{Togodb.url_scheme}://#{Togodb.api_server}/entry/#{@table.name}/#{params[:id]}"
    end
  end

  def quickbrowse_edit_form
    @columns = @table.columns
    @record = @table.active_record.find(params[:id])
  end

  def create
    @error_message = nil
    begin
      model = @table.active_record
      record_params = params.require(@table.name).permit(@table.columns.map(&:internal_name))
      model.create!(record_params)
    rescue => e
      @error_message = "ERROR: #{e.message}"
    end
  end

  def update
    @error_message = nil
    begin
      entry = @table.active_record.find(params[:id])
      record_params = params.require(@table.name).permit(@table.columns.map(&:internal_name))
      entry.update!(record_params)
    rescue => e
      @error_message = "ERROR: #{e.message}"
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      ids = JSON.parse(params[:ids])
      @table.active_record.destroy(ids)
    end
  end

  private

  def set_table
    @table = @db = togodb_table_instance_by_name(params[:db])
  end

  def preview_html
    model_attr = parse_column_params

    @columns = []
    model_attr.keys.each do |id|
      column = TogodbColumn.find(id)
      model_attr[id].delete('id_separator_pdl')
      column.update!(model_attr[id])
      @columns << column
    end

    if params[:id]
      @id = params[:id]
      @record = @table.active_record.find(@id)
    else
      pk_col_id = @table.pkey_col_id
      pk_column = if pk_col_id
                    TogodbColumn.find(pk_col_id).internal_name
                  else
                    'id'
                  end
      @record = @table.active_record.order(pk_column).first
      @id = @record[pk_column]
    end
    @record_name = record_name(@table, @record)

    set_page_setting(@table)

    register_fs_helper(@id)
    @page_head = page_head_html
    @page_body = page_body_html

    render 'show'
  end

  def page_head_html
    html = if @preview
             params[:header]
           else
             if @page_setting && !@page_setting.show_header.blank?
               @page_setting.show_header
             else
               entry_head_default
             end
           end

    template = FlavourSaver::Template.new { prepare_template html }
    template.render
  end

  def page_body_html
    body_html = if @preview
                  params[:body]
                else
                  if @page_setting && !@page_setting.show_body.blank?
                    @page_setting.show_body
                  else
                    entry_body_default
                  end
                end

    template = FlavourSaver::Template.new { prepare_template body_html }
    template.render
  end

  def prepare_template(tmpl)
    new_template = tmpl.clone
    @columns.each do |column|
      if !column.sanitize? || column.sequence_type?
        # Do not escape HTML
        new_template.gsub!("{{#{column.name}_value}}", "{{{#{column.name}_value}}}")
      end
    end

    new_template
  end

  def register_fs_helper(id_value)
    FS.register_helper("id_value") { id_value }
    @columns.each do |column|
      FS.register_helper("#{column.name}_label") { column.label }
      #v = if column.sequence_type?
      #      html_value(@record, column)
      #    else
      #      @record[column.internal_name]
      #    end
      v = html_value(@record, column)
      FS.register_helper("#{column.name}_value") { v }
    end
  end

  def hash_for_json
    record_name = @record_name.respond_to?(:gsub) ? @record_name.gsub(/["\\]/) { |q| '\\' + q } : @record_name
    data = { @table.name => {}, :record_name => record_name, :raw_value => {} }
    @columns.each do |column|
      data[@table.name][column.name] = {
        label: column.label,
        value: html_value(@record, column),
        sanitize: column.sanitize ? 1 : 0
      }
      data[:raw_value][column.internal_name] = @record[column.internal_name]
    end

    data
  end

  def array_for_key_value_metastanza
    generator = MetaStanza::DataGenerator::KeyValue.new(@table)

    generator.generate(@id)
  end
end
