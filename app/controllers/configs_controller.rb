class ConfigsController < ApplicationController
  protect_from_forgery

  before_action :set_table
  before_action :execute_user_required
  #before_action :set_page, except: [ :show, :find_user ]

  def show
    unless @table.has_resource_label?
      @table.resource_label = @table.resource_label_default
      @table.save
    end

    @columns = columns(@table)

    @page = TogodbPage.find_by_table_id(@table.id)
    unless @page
      @page = create_page
    end

    set_metadata(@table)
    set_roles(@table)

    @column = TogodbColumn.new(table_id: @table.id)
    set_datasets

    @tables = @user.configurable_tables
    @class_map = ClassMap.by_table(@table)
  end

  def find_user
    @searched_user_name = params[:login]
    @user = TogodbUser.where(login: params[:login]).first
    if @user
      @privileged_user = TogodbRole.exists?(table_id: @table.id, user_id: @user.id)
    end
  end

  def update_roles
    # "roles" =>
    #    {"726"=>{"role_read"=>"0", "role_write"=>"0", "role_execute"=>"0", "role_admin"=>"1"},
    #     "727"=>{"role_read"=>"0", "role_write"=>"0", "role_execute"=>"0", "role_admin"=>"1"}}
    # Key of "roles" is togodb_roles.id

    unless current_user.execute_table?(@table)
      message = "You don't have permission to access this page."
      render plain: message
      return
    end

    begin
      ActiveRecord::Base.transaction do
        params[:roles].to_unsafe_h.keys.each do |id|
          role = TogodbRole.find(id)
          role.update!(role_params(id))
        end
      end
    rescue => e
      render_error_message('togodb-db-user-add-search-msg', e.message)
    end
  end

  private

  def set_page
    @page = TogodbPage.find(params[:id])
  end

  def set_metadata(table)
    @metadata = TogodbDbMetadata.find_by_table_id(table.id)
    unless @metadata
      @metadata = TogodbDbMetadata.create(
          table_id: table.id
      )
    end
    @metadata_pubmeds = TogodbDbMetadataPubmed.where(db_metadata_id: @metadata.id)
    @metadata_dois = TogodbDbMetadataDoi.where(db_metadata_id: @metadata.id)
  end

  def role_params(id)
    params[:roles].require(id).permit(:role_admin, :role_read, :role_write, :role_execute)
  end

end
