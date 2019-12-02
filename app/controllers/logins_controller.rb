class LoginsController < ApplicationController
  protect_from_forgery except: :openid

  def show; end

  def openid
    if params[:openid_identifier]
      uri = URI.parse(params[:openid_identifier])
      raise 'Please use DBCLS OpenID.' if uri.host != 'openid.dbcls.jp'

      user = TogodbUser.find_by_login(params[:openid_identifier])
      raise 'You cannot use TogoDB.' if user&.deleted
    end

    open_id_authentication if using_open_id?
  end

  def account
    if user = TogodbUser.authorize(params[:login], params[:password])
      if user.active?
        successful_login(user)
      else
        message = 'Your account has been deleted. You cannot use TogoDB.'
        failed_login(message, :account_login_error)
      end
    else
      message = "Sorry, that username/password doesn't work"
      failed_login(message, :account_login_error)
    end
  end

  protected

  def open_id_authentication
    options = {
      trust_root: @app_server,
      return_to: "#{request.headers['HTTP_REFERER']}/openid?_method=post"
    }
    authenticate_with_open_id(nil, options) do |result, identity_url|
      if result.successful?
        user = TogodbUser.regist(identity_url)
        successful_login(user)
      else
        failed_login result.message
      end
    end
  end

  private

  def login_required?
    false
  end

  def successful_login(user)
    raise TypeError, 'TogodbUser is expected, but got %s' % user.class unless user.is_a?(TogodbUser)
    set_current_user(user.id)
    redirect_to list_url
  end

  def failed_login(message, error_type = :error)
    flash[error_type] = message.to_s
    redirect_to_login
  end
end
