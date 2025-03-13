require 'sidekiq'

# Configure Redis connection
redis_config = {
  url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' },
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # Only if using Redis over SSL
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Add middleware for retries with exponential backoff
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, max_retries: 5
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Set Sidekiq as the ActiveJob queue adapter
Rails.application.config.active_job.queue_adapter = :sidekiq
