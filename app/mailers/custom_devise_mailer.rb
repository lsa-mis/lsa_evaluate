class CustomDeviseMailer < Devise::Mailer
  # Disable password change notifications
  def password_change(record, opts = {})
    # Override without sending an email
  end
end
