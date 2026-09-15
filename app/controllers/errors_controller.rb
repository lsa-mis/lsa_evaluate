# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!

  def not_found
    logger.info('!!!!!!! Handling 404 Not Found error')
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  def internal_server_error
    logger.info('!!!!!!! Handling 500 Internal Server Error')
    respond_to do |format|
      format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end
end
