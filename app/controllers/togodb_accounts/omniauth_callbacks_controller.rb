# frozen_string_literal: true

class TogodbAccounts::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # More info at:
  # https://github.com/heartcombo/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end

  skip_before_action :verify_authenticity_token, only: %i[github google_oauth2]

  def github
    callback_for(:github)
  end

  def google_oauth2
    callback_for(:google)
  end

  def callback_for(provider)
    @user = TogodbAccount.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = request.env['omniauth.auth'].except(:extra)
      redirect_to new_togodb_account_registration_url
    end
  end

  def failure
    redirect_to login_path
  end
end
