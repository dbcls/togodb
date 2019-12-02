class LogoutsController < ApplicationController

  def show
    set_current_user(nil)
    redirect_to_login
  end

end
