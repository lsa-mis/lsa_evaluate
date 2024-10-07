# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper
  before_action :authenticate_user!

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

  # Use around_action to handle exceptions from both actions and callbacks
  around_action :handle_exceptions

  protected

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  # Around action method to handle exceptions
  def handle_exceptions
    yield
  rescue Pundit::NotAuthorizedError => exception
    Rails.logger.info('!!!! Handling Pundit::NotAuthorizedError in ApplicationController')
    user_not_authorized(exception)
  rescue ActiveRecord::RecordNotFound => exception
    Rails.logger.info('!!!! Handling ActiveRecord::RecordNotFound in ApplicationController')
    render404(exception)
  rescue StandardError => exception
    Rails.logger.info("!!!! Handling StandardError (Exception Class: #{exception.class}), Message: #{exception.message}")
    render500(exception)
  end

  # Private method for handling Pundit not authorized errors
  def user_not_authorized(exception)
    logger.info('!!!!!!! Handling Pundit::NotAuthorizedError in ApplicationController')
    policy_name = exception.policy.class.to_s.underscore
    message = "You are not authorized to perform #{exception.query} on #{policy_name.humanize}."

    flash[:alert] = message
    Rails.logger.error("Pundit error: #{message} - User: #{current_user&.id}, Action: #{exception.query}, Policy: #{policy_name}")

    # Redirect back or to root if referer is not available
    redirect_to(request.referer || root_path)
  end

  # Handle 404 errors (Record Not Found)
  def render404(exception)
    logger.info('!!!!!!! Handling RecordNotFound error')
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  # Handle 500 errors (Standard Error)
  def render500(exception)
    log_exception(exception)
    logger.error("!!!!!!! Handling StandardError (Exception Class: #{exception.class}), Message: #{exception.message}")

    respond_to do |format|
      format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end

  # Log exceptions in detail
  def log_exception(exception)
    logger.error("!!!!!!!!!!! StandardError: #{exception.class} - #{exception.message}")
    logger.error(exception.backtrace.join("\n"))
  end
end
