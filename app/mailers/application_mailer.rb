# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "University of Michigan - LSA Evaluate <#{Rails.application.credentials.dig(:sendgrid, :mailer_sender)}>",
          reply_to: 'LSA Evaluate Support <lsa-evaluate-support@umich.edu>'

  layout 'mailer'

  before_action :attach_logo

  private

  def attach_logo
    logo_path = Rails.root.join('app/assets/images/U-M_Logo.png')
    if File.exist?(logo_path)
      attachments.inline['U-M_Logo.png'] = File.read(logo_path)
    else
      Rails.logger.warn "Logo file not found: #{logo_path}. Please create a PNG version of U-M_Logo.svg for email compatibility."
    end
  rescue => e
    Rails.logger.error "Failed to attach logo: #{e.message}"
  end
end
