# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper
  include Pagy::Method
  include ContestInviteSession
  before_action :authenticate_user!
  before_action :set_sentry_context


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
    # SAML POSTs from the IdP often arrive without the Rails session cookie
    # (SameSite). Prefer RelayState / omniauth.origin, which survive that round-trip.
    saml_preserved_return_path ||
      safe_internal_redirect_path(stored_location_for(resource)) ||
      default_sign_in_path_for(resource)
  end

  def default_sign_in_path_for(resource)
    resource.judge? ? judge_dashboard_path : root_path
  end

  def saml_preserved_return_path
    safe_internal_redirect_path(request.params['RelayState']) ||
      safe_internal_redirect_path(request.env['omniauth.origin'])
  end

  def safe_internal_redirect_path(path)
    return if path.blank?

    uri = URI.parse(path)
    if uri.host.present?
      return unless uri.host == request.host

      path = [ uri.path, uri.query ].compact.join('?')
    end

    return unless path.start_with?('/') && !path.start_with?('//')

    # Homepage / login origins are not meaningful return destinations; fall
    # through to role-based defaults (e.g. judges → judge dashboard).
    path_only = path.split('?', 2).first
    return if path_only.blank? || path_only == '/' || path_only == root_path

    path
  rescue URI::InvalidURIError
    nil
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  # Around action method to handle exceptions
  def handle_exceptions
    yield
  rescue Pundit::NotAuthorizedError => exception
    # Rails.logger.info('!!!! Handling Pundit::NotAuthorizedError in ApplicationController')
    user_not_authorized(exception)
  rescue ActiveRecord::RecordNotFound => exception
    Rails.logger.info('!!!!!!! Handling ActiveRecord::RecordNotFound in ApplicationController')
    redirect_to root_path, alert: '!!! Not authorized !!!'
  end

  # Private method for handling Pundit not authorized errors
  def user_not_authorized(exception)
    logger.info('!!!!!!! Handling Pundit::NotAuthorizedError in ApplicationController')
    policy_name = exception.policy.class.to_s.underscore
    message = '!!! Not authorized !!!'

    flash[:alert] = message
    Rails.logger.error("#!#!#!# Pundit error: #{message} - User: #{current_user&.id}, Action: #{exception.query}, Policy: #{policy_name.humanize}")

    # Redirect back or to root if referer is not available
    redirect_to(request.referer || root_path)
  end

  # Log exceptions in detail
  def log_exception(exception)
    logger.error("!!!!!!! StandardError: #{exception.class} - #{exception.message}")
    logger.error(exception.backtrace.join("\n"))
  end

  def set_sentry_context
    if current_user
      Sentry.set_user(id: current_user.id, email: current_user.email)
    end

    Sentry.set_context('request', {
      controller: controller_name,
      action: action_name,
      params: request.filtered_parameters.except('controller', 'action')
    })
  end
end
