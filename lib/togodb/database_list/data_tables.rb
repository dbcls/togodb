module Togodb
  class DatabaseList
    class DataTables < Togodb::DataTables
      include ActionView::Helpers::NumberHelper
      include Togodb::Management

      class << self
        def columns
          [
              {
                  name: 'name',
                  label: 'Name',
                  method: 'name_text',
                  prop: '{"sClass": "left"}'
              },
              {
                  name: 'enabled',
                  label: 'Access',
                  method: 'access_text',
                  prop: '{"sClass": "center"}'
              },
              {
                  name: nil,
                  label: 'Action',
                  method: 'action_text',
                  prop: '{"sClass": "center", "bSortable": false}'
              },
              {
                  name: 'num_records',
                  label: 'Num records',
                  method: 'numrecords_text',
                  prop: '{"sClass": "right"}'
              },
              {
                  name: 'created_at',
                  label: 'Date created',
                  method: 'created_text',
                  prop: '{"sClass": "center"}'
              },
              {
                  name: 'creator_id',
                  label: 'Creator',
                  method: 'creator_text',
                  prop: '{"sClass": "left"}'
              }
          ]
        end
      end

      def initialize(datatables_params)
        super(datatables_params)
        @records = tables
      end

      def list_records
        conditions = list_conditions
        if conditions == false
          @filtered_total = 0
          []
        else
          @filtered_total = TogodbTable.where(list_conditions).count
          TogodbTable.joins(ar_joins).select(ar_select).where(conditions).offset(list_offset).limit(list_limit).order(list_orders)
        end
      end

      def list_orders
        if num_sort_columns == 0
          ['name ASC']
        else
          orders = []
          num_sort_columns.times { |i|
            if sort_field(i) == 'creator_id'
              orders << "togodb_users.login #{sort_dir(i)}"
            else
              orders << "#{sort_field(i)} #{sort_dir(i)}"
            end
          }
          orders
        end
      end

      def ar_select
        'togodb_users.login,togodb_tables.id,' + columns.select { |c| c[:name] }.map { |c| "togodb_tables.#{c[:name]}" }.join(',')
      end

      def ar_joins
        'LEFT OUTER JOIN togodb_users ON togodb_tables.creator_id = togodb_users.id'
      end

      def name_text(table)
        table.id
      end

      def access_text(table)
        table.enabled? ? 'Public' : 'Private'
      end

      def creator_text(table)
        begin
          table.creator.login
        rescue
          '[Unknown]'
        end
      end

      def numrecords_text(table)
        begin
          number_with_delimiter(table.num_records)
        rescue ActiveRecord::StatementInvalid
          '[Unknown]'
        end
      end

      def created_text(table)
        begin
          table.created_at.to_s
        rescue
          '[Unknown]'
        end
      end

      def action_text(table)
        actions = []

        if allow_execute?(@current_user, table)
          actions << "<a href=\"/config/#{table.name}\">Config</a>"
        end

        if admin_user?(@current_user, table)
          actions << "<a href=\"/config/copy/#{table.name}\">Copy</a>"
          actions << "<a href=\"/append/db/#{table.name}\">Append</a>"
          actions << %|<a id="togodb-dblist-delete-db-link-#{table.id}" href="#" onclick="show_delete_db_confirm_dialog('#{table.id}', '#{table.name}'); return false;">Delete</a>|
        end

        ''
      end

      def total_size
        @records.size
      end

    end
  end
end
