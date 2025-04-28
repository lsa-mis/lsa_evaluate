# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "University of Michigan - LSA Evaluate <#{Rails.application.credentials.dig(:sendgrid, :mailer_sender)}>",
          reply_to: 'LSA Evaluate Support <lsa-evaluate-support@umich.edu>'

  layout 'mailer'

  before_action :attach_logo

  private

  def attach_logo
    attachments.inline['U-M_Logo.svg'] = File.read(Rails.root.join('app/assets/images/U-M_Logo.svg'))
  end
end
