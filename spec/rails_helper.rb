# frozen_string_literal: true

require 'spec_helper'
require 'database_cleaner/active_record'
require 'pundit/matchers'
require 'faker'
require 'omniauth'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation if the environment is running in production
abort('The Rails environment is running in production mode!') if Rails.env.production?

# Add additional requires below this line. Rails is not loaded until this point!
require 'rspec/rails'
require 'factory_bot_rails'
require 'pundit/rspec'
require 'selenium-webdriver'
require 'capybara/rails'

puts "!*!*!*! Running in environment: #{Rails.env} !*!*!*!"
puts "!*!*!*! Running SHOW_BROWSER?: #{ENV['SHOW_BROWSER'].present? ? '✅' : '🙈'} !*!*!*!"

Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }
# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Pundit::Matchers, type: :policy
  config.include ActiveSupport::Testing::TimeHelpers
  config.fixture_paths = [ Rails.root.join('spec/fixtures').to_s ]

  # Disable transactional fixtures because we're using DatabaseCleaner
  config.use_transactional_fixtures = false

  # Clean the database with truncation before the test suite runs
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # Configure DatabaseCleaner

  config.around do |example|
    if example.metadata[:type] == :system
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Include Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.include RequestSpecHelpers, type: :request

  # Remove this duplicate line as we're already requiring support files above
  # Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  # Include Warden helpers if needed
  config.include Warden::Test::Helpers

  # Reset Warden after each test
  config.after do
    Warden.test_reset!
  end

  config.before(:each, type: :request) do
    host! 'localhost'
  end

  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :system
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  OmniAuth.config.test_mode = true

  config.before do
    OmniAuth.config.mock_auth[:saml] = nil
  end

  # Add this to prevent OmniAuth from raising errors during testing
  config.before do
    OmniAuth.config.logger = Logger.new('/dev/null')
    OmniAuth.config.on_failure = proc { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
  end

  # Configure Capybara for system tests
  config.before(:each, type: :system) do
    if ENV['SHOW_BROWSER'].present?
      driven_by :selenium_chrome
    else
      driven_by :selenium_chrome_headless
    end
    Capybara.default_max_wait_time = 5
  end

  # Use rack_test driver for specific tests that need response headers
  config.before(:each, type: :system, js: false) do
    driven_by :rack_test
  end
end
