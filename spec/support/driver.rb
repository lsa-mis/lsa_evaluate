# frozen_string_literal: true

browser_options = Selenium::WebDriver::Firefox::Options.new
browser_options.add_argument('--window-size=1920,1080')

webdriver_options = {
  browser: :firefox,
  options: browser_options
}

# Only add the headless argument if SHOW_BROWSER is blank
browser_options.add_argument('--headless') if ENV['SHOW_BROWSER'].blank?

if ENV['TEST_SERVER_PORT'].present?
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = ENV['TEST_SERVER_PORT']
  webdriver_options[:url] = "http://#{ENV.fetch('HOST_MACHINE_IP', nil)}:9515"
end

# Increase default wait time
Capybara.default_max_wait_time = 10

# Register the non-headless selenium_firefox driver
Capybara.register_driver :selenium_firefox do |app|
  Capybara::Selenium::Driver.new(app, **webdriver_options)
end

# Register the headless driver separately
Capybara.register_driver :selenium_firefox_headless do |app|
  Capybara::Selenium::Driver.new(app, **webdriver_options.merge({ options: browser_options }))
end

# Set javascript driver to the headless version by default
Capybara.javascript_driver = :selenium_firefox_headless

RSpec.configure do |config|
  # Choose the correct driver based on the SHOW_BROWSER environment variable
  config.before(:each, type: :system) do
    driven_by ENV['SHOW_BROWSER'].present? ? :selenium_firefox : :selenium_firefox_headless
  end

  # Add debugging for system tests
  config.after(:each, type: :system) do |example|
    if example.exception
      puts "Page HTML at failure:"
      puts page.html
      puts "Current URL: #{page.current_url}"
    end
  end
end

# How to use this snippet:
# SHOW_BROWSER=true bundle exec rspec spec/system/contest_description_filter_spec.rb
