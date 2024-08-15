# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  load_and_authorize_resource unless: :devise_controller?
  include ApplicationHelper

  # rescue_from CanCan::AccessDenied do |exception|
  #   logger.error("!!!!!!!!!!! CanCan error: #{exception.message}")
  #   respond_to do |format|
  #     format.html { redirect_to root_path, alert: 'You are not authorized for that action' }
  #     format.json { render json: { error: 'You are not authorized for that action' }, status: :forbidden }
  #   end
  # end

  # rescue_from ActiveRecord::RecordNotFound, with: :render404
  # rescue_from StandardError, with: :render500

  # def render404
  #   respond_to do |format|
  #     format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
  #     format.json { render json: { error: 'Not Found' }, status: :not_found }
  #   end
  # end

  # def render500(exception)
  #   # Log the error, send it to error tracking services, etc.
  #   logger.error("!!!!!!!!!!! StandardError: #{exception.message}")
  #   logger.error(exception.backtrace.join("\n"))

  #   if exception.message.include?('You are not authorized')
  #     respond_to do |format|
  #       format.html { redirect_to root_path, alert: 'You are not authorized for that action' }
  #       format.json { render json: { error: 'You are not authorized for that action' }, status: :forbidden }
  #     end
  #   else
  #     respond_to do |format|
  #       format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
  #       format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
  #     end
  #   end
  # end
end
