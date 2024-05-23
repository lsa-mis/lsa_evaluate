# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  prepend_view_path 'app/views/mailers'
  default from: Rails.application.credentials.dig(:devise, :mailer_sender)
  layout 'mailer'
end
