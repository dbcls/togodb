class UsersController < ApplicationController

  before_action :set_user, only: %i[edit update destroy toggle_deleted]

  def index
    datatables = Togodb::AccountList::DataTables.new(params)
    #callback = params[:callback].blank? ? 'callback' : params[:callback]
    #render json: datatables.list_data.jsonize, callback: callback

    render json: datatables.list_data.to_json
  end

  def new
    @user = TogodbUser.new
    @user.import_table = true
  end

  def create
    @user = TogodbUser.new(user_params)

    respond_to do |format|
      if @user.save
        format.html {
          flash[:notice] = success_message('created')
          redirect_to account_url
        }
      else
      end
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html {
          flash[:notice] = success_message('updated')
          redirect_to account_url
        }
      else
      end
    end
  end

  def destroy
    respond_to do |format|
      if @user.update(user_params)
        format.html {
          flash[:notice] = success_message(@user.deleted ? 'disabled' : 'enabled')
          redirect_to account_url
        }
      else
      end
    end
  end

  def toggle_deleted; end

  private

  def success_message(action)
    %(User account "#{@user.login}" has been #{action} successfully.)
  end

  def permit_params
    %i[login password superuser import_table deleted]
  end

  def set_user
    @user = TogodbUser.find(params[:id])
  end

  def user_params
    if params[:user]
      params.require(:user).permit(permit_params)
    elsif params[:togodb_user]
      params.require(:togodb_user).permit(permit_params)
    end
  end

end
