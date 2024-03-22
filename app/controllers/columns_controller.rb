class ColumnsController < ApplicationController
  include Togodb::DB::Pgsql

  class InvalidColumn < StandardError; end

  def create
    elem_id = 'add-column-dialog-message'

    errors = validate_new_column
    unless errors.empty?
      render partial: 'set_error_message', locals: { element_id: elem_id, message: errors }
      return
    end

    error = add_column
    if error
      render partial: 'set_error_message', locals: { element_id: elem_id, message: error }
    else
      # render 'create.js'
    end
  end

  def graph_edit_html
    column = TogodbColumn.find(params[:id])
    table = TogodbTable.find(column.table_id)
    @columns = columns(table)
    @togodb_graph =
      TogodbGraph.find_by(togodb_column_id: column.id) || TogodbGraph.create!(togodb_column_id: column.id)

    render partial: 'configs/columns_graph_contents'
  end

  private

  def validate_new_column
    errors = []

    begin
      @table = TogodbTable.find(params[:togodb_column][:table_id])
    rescue
      errors << "Database not found."
    end

    name = params[:togodb_column][:name].strip
    if name.blank?
      errors << "Name is required."
    else
      if Togodb.valid_column_name?(name)
        if @table && @table.columns.map(&:name).include?(params[:togodb_column][:name])
          errors << "Column '#{name}' already exists."
        end
      else
        errors << "Column '#{name}' is not valid column name."
      end
    end

    errors
  end

  def add_column
    error = nil

    # params[:togodb_column] => {name: 'ColName', data_type: 'ColType', label: 'ColLabel'}
    attr = {
      name: params[:togodb_column][:name].strip,
      data_type: params[:togodb_column][:data_type],
      label: params[:togodb_column][:label]
    }

    if (params[:togodb_column][:label].nil? || /\A\s*\z/ =~ params[:togodb_column][:label])
      attr[:label] = attr[:name].capitalize
    end

    attr[:internal_name] = "#{Togodb::COLUMN_PREFIX}#{attr[:name]}"

    if params[:togodb_column][:data_type] == 'sequence'
      attr[:data_type] = 'text'
      attr[:other_type] = 'sequence'
    elsif params[:togodb_column][:data_type] == 'list'
      attr[:data_type] = 'string'
      attr[:other_type] = 'list'
    end

    begin
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.add_column @table.name, attr[:internal_name], attr[:data_type].to_sym
        create_btree_index(@table.name, attr[:internal_name])
        if attr[:data_type] == 'string' || attr[:data_type] == 'text'
          create_gin_index(@table.name, attr[:internal_name])
        end

        new_column = TogodbColumn.create!(TogodbColumn.default_values(@table, attr[:data_type], attr[:other_type]).merge(attr))

        if new_column.nil? || new_column.new_record?
          error = "ERROR: column '#{attr[:name]}' is not added."
        else
          flash[:column_setting_notice] = "Column '#{attr[:name]}' has been added successfully."
        end
      end
    rescue => e
      error = e.message
    end

    error
  end
end
