# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pundit::Authorization
  include ApplicationHelper

  # Custom flash logging (optional)
  def flash
    super.tap do |flash_hash|
      if flash_hash.present?
        flash_hash.each do |type, message|
          Rails.logger.info("*!**!*!**!*!**!*! Flash message set: Type: #{type}, Message: '#{message}', Controller: #{controller_name}, Action: #{action_name}")
        end
      end
    end
  end

  # Rescue from authorization errors
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Pundit::NotAuthorizedError do |exception|
    Rails.logger.info("!!!! Handling Pundit::NotAuthorizedError in ApplicationController")
    user_not_authorized(exception)
  end
  rescue_from ActiveRecord::RecordNotFound, with: :render404
  rescue_from StandardError, with: :render500

  # Handle 404 errors (Record Not Found)
  def render404
    logger.info("!!!!!!! Handling RecordNotFound error")
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  # Handle 500 errors (Standard Error)
  def render500(exception)
    log_exception(exception)
    logger.info("!!!!!!! Handling StandardError (Exception Class: #{exception.class})")

    respond_to do |format|
      format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end

  # Private method for handling Pundit not authorized errors
  private

  def user_not_authorized(exception)
    logger.info("!!!!!!! Handling Pundit::NotAuthorizedError")
    policy_name = exception.policy.class.to_s.underscore
    message = "You are not authorized to perform #{exception.query} on #{policy_name.humanize}"

    flash[:alert] = message
    Rails.logger.error("Pundit error: #{message} - User: #{current_user.id}, Action: #{exception.query}, Policy: #{policy_name}")

    # Redirect back or to root if referer is not available
    redirect_to(request.referer || root_path)
  end

  # Log exceptions in detail
  def log_exception(exception)
    logger.error("!!!!!!!!!!! StandardError: #{exception.class} - #{exception.message}")
    logger.error(exception.backtrace.join("\n"))
  end
end
