module Togodb
  class Release
    include Togodb::Management

    ACTIONS = %w[index list db].freeze

    def initialize(user, params = {})
      @user = user
      @params = params.clone
    end

    def list_data
      datatables = if @user.superuser?
                     Togodb::ReleaseList::DataTables::All.new(@params, @user)
                   else
                     Togodb::ReleaseList::DataTables::Personal.new(@params, @user)
                   end

      datatables.list_data
    end

  end
end
