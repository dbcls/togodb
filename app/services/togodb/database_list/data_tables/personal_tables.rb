module Togodb
  class DatabaseList
    class DataTables
      class PersonalTables < Togodb::DatabaseList::DataTables

        def initialize(datatables_params, current_user)
          @current_user = current_user
          super(datatables_params)
        end

        def list_conditions
          roles = TogodbRole.where(user_id: @current_user.id)
          if roles.empty?
            conditions = false
          else
            if @query.blank?
              conditions = ["togodb_tables.id IN (#{roles.map(&:table_id).join(',')})"]
            else
              conditions = ["togodb_tables.name LIKE ? AND togodb_tables.id IN (#{roles.map(&:table_id).join(',')})", "%#{@query}%"]
            end
          end

          conditions
        end

        def tables
          roles = TogodbRole.where(user_id: @current_user.id)
          if roles.empty?
            []
          else
            TogodbTable.where(id: roles.map(&:table_id)).order(:name)
          end
        end

      end
    end
  end
end
