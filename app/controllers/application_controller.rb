# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper
  include Pagy::Backend
  include SecurityProtection
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

  def after_sign_in_path_for(resource)
    if resource.judge?
      judge_dashboard_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  # Around action method to handle exceptions
  def handle_exceptions
    yield
  rescue Pundit::NotAuthorizedError => exception
    logger.info('!!!!!!! Handling Pundit::NotAuthorizedError in ApplicationController')
    policy_name = exception.policy.class.to_s.underscore
    message = '!!! Not authorized !!!'

    flash[:alert] = message
    Rails.logger.error("#!#!#!# Pundit error: #{message} - User: #{current_user&.id}, Action: #{exception.query}, Policy: #{policy_name.humanize}")

    redirect_to root_path
  rescue ActiveRecord::RecordNotFound => exception
    Rails.logger.info('!!!!!!! Handling ActiveRecord::RecordNotFound in ApplicationController')
    redirect_to not_found_path
  end

  # Log exceptions in detail
  def log_exception(exception)
    logger.error("!!!!!!! StandardError: #{exception.class} - #{exception.message}")
    logger.error(exception.backtrace.join("\n"))
  end
end
