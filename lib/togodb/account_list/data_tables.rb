module Togodb
  class AccountList
    class DataTables < Togodb::DataTables

      class << self
        def columns
          [
              { name: 'login', label: 'Login', method: 'login_text', prop: '{"sClass": left}' },
              { name: 'role', label: 'Role', method: 'role_text', prop: '{"sClass": left, "bSortable": false}' },
              { name: 'deleted', label: 'Deleted', method: 'deleted_text', prop: '{"sClass": left, "bSortable": false}' },
              { name: 'action', label: 'Action', method: 'action_text', prop: '{"sClass": "left", "bSortable": false}' }
          ]
        end
      end

      attr_accessor :total_size

      def initialize(datatables_params)
        super(datatables_params)
        @total_size = TogodbUser.count
      end

      def list_records
        where = list_conditions
        @filtered_total = TogodbUser.where(where).count
        TogodbUser.where(where).order(sort_order).offset(list_offset).limit(list_limit)
      end

      def list_conditions
        if @params[:sSearch].blank?
          nil
        else
          ['login LIKE ?', "%#{@params[:sSearch]}%"]
        end
      end

      def sort_order
        sort_dir = 'ASC'
        if @params[:sSortDir_0].to_s.upcase == 'DESC'
          sort_dir = 'DESC'
        end

        sort_column = 'login'
        begin
          sort_column = self.class.columns[@params[:iSortCol_0].to_i][:name]
        rescue
          sort_column = 'login'
        end

        "#{sort_column} #{sort_dir}"
      end

      def list_offset
        @params[:iDisplayStart].blank? ? 0 : @params[:iDisplayStart].to_i
      end

      def list_limit
        @params[:iDisplayLength].blank? ? 10 : @params[:iDisplayLength].to_i
      end

      def login_text(user)
        user.login
      end

      def role_text(user)
        user.role_for_disp
      end

      def deleted_text(user)
        user.deleted.to_s
      end

      def action_text(user)
        actions = []

        actions << %(<a href="/users/#{user.id}/edit.js" data-remote="true">Edit</a>)
        unless user.login == 'root'
          actions << %(<a class="togodb-account-user-onoff" href="/users/#{user.id}/toggle_deleted.js" data-remote="true">#{user.deleted ? "Enable" : "Disable"}</a>)
        end

        actions.join(' | ')
      end
    end
  end
end
