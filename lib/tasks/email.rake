namespace :email do
  # Direct delivery:
  # bin/rails email:test[your@email.com]
  #
  # Queue via Active Job / Solid Queue:
  # bin/rails email:test[your@email.com,true]

  desc 'Send a test email to verify configuration'
  task :test, [ :email, :queue ] => :environment do |_t, args|
    recipient = args[:email] || Rails.application.credentials.dig(:sendgrid, :mailer_sender)
    queue_delivery = args[:queue]&.downcase == 'true'

    if recipient.nil?
      puts 'ERROR: No recipient email provided and no default contact email configured.'
      puts 'Usage: rake email:test[recipient@example.com] or rake email:test[recipient@email.com,true] to queue via Active Job'
      exit 1
    end

    puts "Sending test email to #{recipient}..."
    begin
      if queue_delivery
        puts "Queuing email delivery through Active Job (#{ActiveJob::Base.queue_adapter.class.name})..."
        TestMailer.test_email(recipient).deliver_later
        puts 'Email successfully queued!'
      else
        mail = TestMailer.test_email(recipient)

        puts 'Message details:'
        puts "  From: #{mail.from.first || 'Not set'}"
        puts "  Reply-To: #{mail.reply_to&.first || 'Not set'}"
        puts "  Subject: #{mail.subject || 'Not set'}"
        puts 'Headers:'
        mail.header.fields.each do |field|
          puts "  #{field.name}: #{field.value}" unless field.name =~ /content-/i
        end

        mail.deliver_now
        puts 'Test email sent directly!'
      end
    rescue => e
      puts "ERROR: Failed to send test email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
