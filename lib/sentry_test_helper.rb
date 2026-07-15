# frozen_string_literal: true

# Helper module for testing Sentry configuration in production
# Usage in Rails console:
#   require './lib/sentry_test_helper'
#   SentryTestHelper.verify_config
#   SentryTestHelper.test_message
#   SentryTestHelper.test_exception
#   SentryTestHelper.full_test
module SentryTestHelper
  class << self
    # Verify Sentry configuration without sending events
    def verify_config
      puts "\n=== Sentry Configuration ==="
      puts "Environment: #{Rails.env}"
      puts "Enabled environments: #{Sentry.configuration.enabled_environments.inspect}"
      puts "Is enabled: #{Sentry.configuration.enabled_environments.include?(Rails.env)}"
      puts "DSN configured: #{Sentry.configuration.dsn.present?}"
      puts "DSN (masked): #{mask_dsn(Sentry.configuration.dsn)}" if Sentry.configuration.dsn
      puts "Error sample rate: #{Sentry.configuration.sample_rate}"
      puts "Traces sampler configured: #{!Sentry.configuration.traces_sampler.nil?}"
      puts "Profiles sample rate: #{Sentry.configuration.profiles_sample_rate}"
      puts "Release: #{Sentry.configuration.release}"
      puts "Environment: #{Sentry.configuration.environment}"
      puts "==========================\n"
    end

    # Send a test message
    def test_message(message = "Test message from #{Rails.env} at #{Time.current}")
      puts "\n=== Testing Sentry Message ==="
      puts "Sending message: #{message}"

      event_id = Sentry.capture_message(message, level: :info)
      puts "Event ID: #{event_id}"
      puts "Status: #{event_id ? 'Sent successfully!' : 'Failed to send (returned nil)'}"
      puts "Note: Check Sentry dashboard in a few moments"
      puts "===========================\n"
      event_id
    end

    # Send a test exception
    def test_exception
      puts "\n=== Testing Sentry Exception ==="

      begin
        raise StandardError, "Test exception from #{Rails.env} at #{Time.current}"
      rescue StandardError => e
        event_id = Sentry.capture_exception(e)
        puts "Exception raised and captured"
        puts "Event ID: #{event_id}"
        puts "Status: #{event_id ? 'Sent successfully!' : 'Failed to send (returned nil)'}"
        puts "Note: Check Sentry dashboard in a few moments"
        puts "=============================\n"
        event_id
      end
    end

    # Full diagnostic test
    def full_test
      verify_config
      sleep 1
      test_message
      sleep 1
      test_exception
      puts "\n✅ Testing complete! Check your Sentry dashboard."
    end

    private

    def mask_dsn(dsn)
      return 'Not configured' if dsn.blank?

      dsn.to_s.gsub(%r{(?<=https://)([^@]+)(?=@)}) { |match| '*' * match.length }
    rescue StandardError
      'Error masking DSN'
    end
  end
end
