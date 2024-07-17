# frozen_string_literal: true

require 'spec_helper'
# require 'database_cleaner'
require 'database_cleaner/active_record'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

# Add additional requires below this line. Rails is not loaded until this point!
require 'rspec/rails'
require 'factory_bot_rails'

puts "!*!*!*! Running in environment: #{Rails.env} !*!*!*!"

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

  config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]

  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Warden::Test::Helpers

  config.before(:each, type: :request) do
    host! 'localhost'
  end

  config.after do
    Warden.test_reset!
  end
end
