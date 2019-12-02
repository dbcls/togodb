class RolesController < ApplicationController

  before_action :set_role, only: %i[update destroy]

  def create
    @role = TogodbRole.new(togodb_role_params)

    respond_to do |format|
      if @role.save
        format.js {
          @roles = togodb_roles(@role.table_id)
        }
      else
      end
    end
  end

  def update
    respond_to do |format|
      if @role.update(togodb_role_params)
        @roles = togodb_roles(@role.table_id)
        format.js
      else
      end
    end
  end

  def destroy
    @table = TogodbTable.find(@role.table_id)
    respond_to do |format|
      if @role.destroy
        set_roles(@table)
        format.js
      end
    end
  end

  def search_user
    @msg_item_id = 'togodb-db-user-add-search-msg'
    begin
      @table = TogodbTable.find(params[:table_id])
    rescue ActiveRecord::RecordNotFound
      message = 'ERROR: No such database.'
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
      return
    end
=begin
    unless allow_execute?(current_user, @table)
      message = "ERROR: You don't have permission to access this page."
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
      return
    end
=end
    login = params[:login].to_s.strip
    @user = TogodbUser.find_by_login(login)

    if @user
      @role = @table.role_for(@user) || TogodbRole.new(table_id: @table.id, user_id: @user.id)
    else
      message = %Q(User "#{params[:login]}" could not be found.)
      render_error_message(@msg_item_id, message)
    end
  end

  private

  def set_role
    @role = TogodbRole.find(params[:id])
  end

  def togodb_role_params
    params.require(:togodb_role).permit(:role_admin, :role_read, :role_write, :role_execute, :table_id, :user_id)
  end

  def togodb_roles(table_id)
    TogodbRole.where(table_id: table_id).includes(:user)
  end

end
