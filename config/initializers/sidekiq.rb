require 'sidekiq'

# Configure Redis connection
redis_config = {
  url: ENV.fetch('REDIS_URL') { "redis://:#{Rails.application.credentials.redis_password}@localhost:6379/1" },
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # Only if using Redis over SSL
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Set default retry count for Sidekiq 7.3.x
  # The retry option is now set in the sidekiq.yml file
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Set Sidekiq as the ActiveJob queue adapter
Rails.application.config.active_job.queue_adapter = :sidekiq
