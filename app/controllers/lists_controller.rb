class ListsController < ApplicationController
  # before_action :require_login
  before_action :authenticate_togodb_account!

  def show
    set_tables(order: 'name')

    if current_user.superuser?
      @production_requests = TogodbProductionRequest.where(accept: nil)
    else
      @requested_tables = []
    end

    @columns = datatable_columns
  end

  def refresh
    col = params[:sort_col] || 'name'
    dir = params[:sort_dir] || 'asc'

    case col
    when 'creator'
      set_tables
      @tables = TogodbTable.joins('LEFT OUTER JOIN togodb_users ON togodb_tables.creator_id = togodb_users.id').where(id: @tables.map(&:id)).order(sort_order(col, dir))
    else
      set_tables(order: sort_order(col, dir))
    end

    render layout: false
  end

  private

  def set_tables(option = {})
    order = if option[:order]
              option[:order]
            else
              'name'
            end

    @tables = current_user.readable_configurable_tables(order)
  end

  def datatable_columns
    Togodb::DatabaseList::DataTables.columns
  end

  def sort_order(column, direction)
    case column
    when 'name'
      "name #{direction}"
    when 'access'
      "enabled #{direction}"
    when 'records'
      "num_records #{direction}"
    when 'date'
      "created_at #{direction}"
    when 'creator'
      "login #{direction}"
    end
  end

end
