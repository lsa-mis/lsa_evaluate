# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  prepend_view_path 'app/views/mailers'
  default from: Rails.application.credentials.dig(:sendgrid, :mailer_sender),
          reply_to: 'lsa-evaluate-support@umich.edu'
  layout 'mailer'
end
