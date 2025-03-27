namespace :email do
  # You can choose whether to queue the email through Sidekiq or send it directly:
  # For direct delivery:
  # bin/rails email:test[your@email.com]
  #
  # To queue through Sidekiq (add true as a second argument):
  # bin/rails email:test[your@email.com,true]

  desc 'Send a test email to verify configuration'
  task :test, [ :email, :queue ] => :environment do |_t, args|
    recipient = args[:email] || Rails.application.credentials.dig(:sendgrid, :mailer_sender)
    queue_delivery = args[:queue]&.downcase == 'true'

    if recipient.nil?
      puts 'ERROR: No recipient email provided and no default contact email configured.'
      puts 'Usage: rake email:test[recipient@example.com] or rake email:test[recipient@example.com,true] to queue via Sidekiq'
      exit 1
    end

    puts "Sending test email to #{recipient}..."
    begin
      # First build the mail object to inspect its properties
      mail = TestMailer.test_email(recipient)

      # Print message details before sending
      puts 'Message details:'
      puts "  From: #{mail.from.first || 'Not set'}"
      puts "  Reply-To: #{mail.reply_to&.first || 'Not set'}"
      puts "  Subject: #{mail.subject || 'Not set'}"
      puts 'Headers:'
      mail.header.fields.each do |field|
        puts "  #{field.name}: #{field.value}" unless field.name =~ /content-/i
      end

      # Now deliver the message based on the queue parameter
      if queue_delivery
        puts 'Queuing email delivery through Sidekiq...'
        mail.deliver_later
        puts 'Email successfully queued in Sidekiq!'
      else
        mail.deliver_now
        puts 'Test email sent directly (bypassing Sidekiq)!'
      end
    rescue => e
      puts "ERROR: Failed to send test email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
