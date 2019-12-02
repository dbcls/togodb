module Togodb
  class ReleaseList
    class DataTables
      class Personal < Togodb::ReleaseList::DataTables

        def initialize(datatables_params, current_user)
          super(datatables_params, current_user)
          @tables = nil
        end

        def list_conditions
          if @query.blank?
            table_conditions
          else
            ["togodb_tables.name LIKE ? AND #{table_conditions}", "%#{@query}%"]
          end
        end

        def table_conditions
          "togodb_tables.id IN (#{tables.map(&:id).join(',')})"
        end

        def tables
          @tables ||= TogodbTable.includes(:roles).where("togodb_roles.user_id=? AND (SUBSTR(togodb_roles.roles,1,1)='1' OR SUBSTR(togodb_roles.roles,2,1)='1' OR SUBSTR(togodb_roles.roles,4,1)='1')", @current_user.id).references(:roles).order(:name)

          @tables
        end

        def total_size
          if tables.empty?
            0
          else
            TogodbDataset.includes(:table).where(table_conditions).references(:table).count
          end
        end

      end
    end
  end
end
