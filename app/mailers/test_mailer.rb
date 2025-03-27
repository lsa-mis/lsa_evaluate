class TestMailer < ApplicationMailer
  def test_email(recipient_email = nil)
    @message = 'This is a test email from LSA Evaluate to verify email configuration.'
    @sender = Rails.application.credentials.dig(:sendgrid, :mailer_sender)
    @reply_to = 'lsa-wads-rails-email-test@umich.edu'

    mail(
      to: recipient_email || 'lsa-wads-rails-email-test@umich.edu',
      subject: 'Test Email from LSA Evaluate'
    )
  end
end
