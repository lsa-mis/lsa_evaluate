require 'sidekiq'

# Configure Redis connection
redis_config = {
  url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' },
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # Only if using Redis over SSL
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # In Sidekiq 7.x, RetryJobs is built-in and configured differently
  # The max_retries setting can be set globally
  config.default_worker_options = { retry: 5 }

  # If you need custom retry logic, you can use a custom middleware
  # config.server_middleware do |chain|
  #   chain.add YourCustomMiddleware
  # end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Set Sidekiq as the ActiveJob queue adapter
Rails.application.config.active_job.queue_adapter = :sidekiq
