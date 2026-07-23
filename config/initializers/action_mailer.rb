# Configure ActionMailer to deliver emails asynchronously via Active Job / Solid Queue
Rails.application.config.action_mailer.deliver_later_queue_name = :default

# Extend ActionMailer to use mail delivery logging
ActiveSupport.on_load(:action_mailer) do
  class << self
    attr_accessor :delivery_notification_method

    def notify_on_delivery(method_name)
      self.delivery_notification_method = method_name
    end
  end

  def notify_delivered
    return unless self.class.delivery_notification_method

    send(self.class.delivery_notification_method, message)
  end
end
