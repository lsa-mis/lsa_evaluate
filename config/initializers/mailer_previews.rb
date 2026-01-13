# frozen_string_literal: true

# Enable mailer previews in production and staging with authorization
# This initializer allows mailer previews to be accessed by authorized users (Collection Administrators and Axis Mundi)

if Rails.env.production? || Rails.env.staging?
  Rails.application.config.to_prepare do
    # Override Rails::MailersController to add authentication and authorization
    if defined?(Rails::MailersController)
      Rails::MailersController.class_eval do
        include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)

        before_action :authenticate_user!
        before_action :authorize_mailer_preview_access!

        private

        def authorize_mailer_preview_access!
          unless current_user&.axis_mundi? || current_user&.administrator?
            redirect_to root_path, alert: 'You are not authorized to access mailer previews.'
          end
        end
      end
    end
  end
end
