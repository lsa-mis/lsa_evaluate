require_relative 'development'

Rails.application.configure do
  config.eager_load = false
  
  # Add logging configuration
  config.log_level = :debug
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger.formatter = Logger::Formatter.new
end
