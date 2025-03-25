# frozen_string_literal: true

# Configure ActionMailer to deliver emails asynchronously using Sidekiq
Rails.application.config.action_mailer.deliver_later_queue_name = :default

# Extend ActionMailer to use mail delivery logging
ActionMailer::Base.class_eval do
  # Add delivery tracking method
  def notify_delivered
    if self.class.delivery_notification_method
      send(self.class.delivery_notification_method, message)
    end
  end

  # Hook into the delivery process
  self.register_observer(-> (message) { message.delivery_method.settings[:return_response] = true })
  self.register_interceptor(-> (message) { message })
  self.register_observer(-> (message) {
    message.deliver_later unless Rails.env.test?
  })

  class << self
    attr_accessor :delivery_notification_method

    # Method to set notification callback
    def notify_on_delivery(method_name)
      self.delivery_notification_method = method_name
    end
  end
end
