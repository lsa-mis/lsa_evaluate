# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pundit::Authorization
  include ApplicationHelper

  def flash
    super.tap do |flash_hash|
      if flash_hash.present?
        flash_hash.each do |type, message|
          Rails.logger.info("*!**!*!**!*!**!*! Flash message set: Type: #{type}, Message: '#{message}', Controller: #{controller_name}, Action: #{action_name}")
        end
      end
    end
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActiveRecord::RecordNotFound, with: :render404
  rescue_from StandardError, with: :render500

  def redirect_back_or_default(notice: '', alert: false, default: root_url)
    if alert
      flash[:alert] = notice
    else
      flash[:notice] = notice
    end
    url = session[:return_to]
    session[:return_to] = nil
    redirect_to(url, anchor: "top" || default)
  end

  def render404
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  def render500(exception)
    # Log the error, send it to error tracking services, etc.
    logger.error("!!!!!!!!!!! StandardError: #{exception.message}")
    logger.error(exception.backtrace.join("\n"))

    if exception.message.include?('You are not authorized')
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'You are not authorized for that action' }
        format.json { render json: { error: 'You are not authorized for that action' }, status: :forbidden }
      end
    else
      respond_to do |format|
        format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
        format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
      end
    end
  end

  private

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    logger.error('!!!!!!!!!!! Pundit error: ')
    redirect_to(request.referer || root_path)
  end
end
