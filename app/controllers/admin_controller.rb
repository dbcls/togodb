class AdminController < ApplicationController
  before_action :super_user_required
  before_action :set_production_request

  def process_production_request
    @production_request.update!(accept: params[:accept], response_comment: params[:response_comment])
    @production_request.table.processed_release_request

    case params[:accept].to_i
    when 1
      accept_request
    when 0
      pending_request
    when -1
      reject_request
    end

    redirect_to list_path
  end

  private

  def accept_request
    @production_request.table.release_to_production

    flash[:process_request_message] =
      "The database #{@production_request.table.name} has been released to the production environment."
  end

  def pending_request
    flash[:process_request_message] =
      "Release request (database: #{@production_request.table.name}) to production environment is pending."
  end

  def reject_request
    flash[:process_request_message] =
      "Release request (database: #{@production_request.table.name}) to production environment is rejected."
  end

  def set_production_request
    @production_request = TogodbProductionRequest.find(params[:production_request_id])
  end
end
