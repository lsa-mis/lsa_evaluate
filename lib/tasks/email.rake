namespace :email do
  desc 'Send a test email to verify configuration'
  task :test, [ :email ] => :environment do |_t, args|
    recipient = args[:email] || Rails.application.credentials.dig(:sendgrid, :mailer_sender)

    if recipient.nil?
      puts 'ERROR: No recipient email provided and no default contact email configured.'
      puts 'Usage: rake email:test[recipient@example.com]'
      exit 1
    end

    puts 'Sending test email to #{recipient}...'
    begin
      email = TestMailer.test_email(recipient).deliver_later
      puts 'Test email sent successfully!'
      puts "Message ID: #{email.message_id || 'Not set'}"
      puts "From: #{email.from.first || 'Not set'}"
      puts "Reply-To: #{email.reply_to&.first || 'Not set'}"
      puts 'Headers:'
      email.header.fields.each do |field|
        puts "  #{field.name}: #{field.value}" unless field.name =~ /content-/i
      end
    rescue => e
      puts "ERROR: Failed to send test email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
