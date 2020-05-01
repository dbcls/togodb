class WelcomeController < ApplicationController
  def index
    @public_databases = TogodbTable.where(enabled: true).order('created_at DESC')

    render layout: false
  end
end
