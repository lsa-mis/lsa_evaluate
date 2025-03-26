# frozen_string_literal: true

# Special configuration for letter_opener with Sidekiq in staging
if Rails.env.staging?
  require 'letter_opener_web'

  # Ensure delivery_method settings are accessible in Sidekiq threads
  Sidekiq.configure_server do |config|
    config.client_middleware do |chain|
      chain.add(Class.new do
        def call(worker_class, job, queue, redis_pool)
          if worker_class == 'ActionMailer::MailDeliveryJob' && Rails.application.config.action_mailer.delivery_method == :letter_opener_web
            # Ensure ActionMailer's settings are correctly set in the Sidekiq context
            ActionMailer::Base.delivery_method = :letter_opener_web
          end
          yield
        end
      end)
    end
  end
end
