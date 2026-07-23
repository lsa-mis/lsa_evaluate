# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 8.1'
ruby '4.0.6'

gem 'actiontext'
gem 'appsignal'
gem 'bootsnap', require: false
gem 'benchmark'
gem 'cgi'
gem 'country_select'
gem 'cssbundling-rails'
gem 'csv', '~> 3.2'
gem 'logger'
gem 'tsort'
gem 'devise', '~> 5.0'
gem 'google-cloud-storage', '~> 1.52'
gem 'image_processing', '~> 1.2'
gem 'jbuilder'
gem 'jsbundling-rails'
gem 'lsa_tdx_feedback', '~> 2.0.1'
gem 'mysql2', '~> 0.5.3'
gem 'net-imap', '>= 0.5'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'
gem 'pagy', '~> 43.0'
gem 'propshaft'
gem 'puma'
gem 'pundit'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'stackprof'
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
gem 'mission_control-jobs'
gem 'simple_form', '~> 5.3'
gem 'stimulus-rails'
gem 'skylight'
gem 'turbo-rails'
gem 'turnout2024', require: 'turnout'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development do
  gem 'better_errors', '>= 2.10'
  gem 'binding_of_caller', '>= 2.0'
  gem 'brakeman'
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano-rails', '~> 1.6', '>= 1.6.1', require: false
  gem 'capistrano-asdf', require: false
  gem 'web-console'
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end

group :development, :staging do
  gem 'letter_opener_web'
end

group :development, :test do
  gem 'capybara'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'pry-rails'
  gem 'pundit-matchers'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rails-omakase', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
end

group :development, :staging, :test do
  gem 'faker'
end
