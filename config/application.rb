# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LsaEvaluate
  class Application < Rails::Application # rubocop:disable Style/Documentation
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    # Add lib to the eager load paths
    config.eager_load_paths << Rails.root.join('lib')
    config.time_zone = 'Eastern Time (US & Canada)'
    config.active_record.default_timezone = :utc
    config.exceptions_app = self.routes

    # Configure CSRF protection to work with OmniAuth SAML
    # This allows SAML callbacks to work properly without disabling CSRF protection
    config.action_controller.forgery_protection_origin_check = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Don't generate system test files.
    config.generators.system_tests = nil

    # Add security middleware
    config.middleware.use Rack::Defense

    # Configure rate limiting
    config.action_dispatch.rate_limiter = {
      limit: 300,
      period: 5.minutes,
      store: :redis,
      key: ->(request) { request.ip }
    }
  end
end

# Custom middleware to block PHP-related requests
class Rack::Defense
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Block requests with PHP-related content
    if request.post? && (
      request.path.include?('.php') ||
      request.query_string.include?('php') ||
      request.content_type.to_s.include?('php') ||
      request.body.read.to_s.include?('php')
    )
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    # Block requests with suspicious headers
    if request.headers['User-Agent'].to_s.include?('Custom-AsyncHttpClient') ||
       request.headers['X-Request-Id'].to_s.include?('cve_2024_4577')
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    # Block known malicious IPs
    suspicious_ips = ['91.99.22.81'] # Add more IPs as needed
    if suspicious_ips.include?(request.ip)
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    @app.call(env)
  end
end
