module Togodb
  class ReleaseList
    class DataTables
      class All < Togodb::ReleaseList::DataTables

        def initialize(datatables_params, current_user)
          super(datatables_params, current_user)
        end

        def list_conditions
          if @query.blank?
            nil
          else
            ['togodb_tables.name LIKE ?', "%#{@query}%"]
          end
        end

        def tables
          TogodbTable.all.order(:name)
        end

        def total_size
          TogodbDataset.count
        end

      end
    end
  end
end
