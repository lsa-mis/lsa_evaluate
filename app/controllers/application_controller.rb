# frozen_string_literal: true

# The ApplicationController is the base class for all controllers in the application.
# It provides common functionality and configuration options for all controllers.
class ApplicationController < ActionController::Base
  # rescue_from ActiveRecord::RecordNotFound, with: :render404
  # rescue_from Exception, with: :render500

  # def render404
  #   respond_to do |format|
  #     format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
  #     format.json { render json: { error: 'Not Found' }, status: :not_found }
  #   end
  # end

  # def render500(_exception)
  #   # Log the error, send it to error tracking services, etc.
  #   respond_to do |format|
  #     format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
  #     format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
  #   end
  # end
end
