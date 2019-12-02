module Togodb
class DatabaseList
class DataTables
class AllTables < Togodb::DatabaseList::DataTables

  def initialize(datatables_params, current_user)
    @current_user = current_user
    super(datatables_params)
  end

  def list_conditions
    if @query.blank?
      nil
    else
      ['togodb_tables.name LIKE ?', "%#{@query}%"]
    end
  end

  def tables
    TogodbTable.order('name')
  end

end
end
end
end
