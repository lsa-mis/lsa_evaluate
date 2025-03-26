# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 7.2'
ruby '3.3.4'

gem 'actiontext'
gem 'bootsnap', require: false
gem 'country_select'
gem 'cssbundling-rails'
gem 'devise', '~> 4.9'
gem 'google-cloud-storage', '~> 1.52'
gem 'image_processing', '~> 1.2'
gem 'jbuilder'
gem 'jsbundling-rails'
gem 'mysql2', '~> 0.5.3'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'
gem 'pagy', '~> 6.4'
gem 'puma'
gem 'pundit'
gem 'redis', '~> 5.0'
gem 'sidekiq', '~> 7.3'
gem 'sassc-rails'
gem 'simple_form', '~> 5.3'
gem 'stimulus-rails'
gem 'skylight'
gem 'turbo-rails'
gem 'turnout2024', require: 'turnout'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano-rails', '~> 1.6', '>= 1.6.1', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-sidekiq', '~> 2.0', require: false
  gem 'web-console'
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webdrivers'
end

group :development, :staging do
  gem 'letter_opener_web'
end

group :development, :test do
  gem 'capybara'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'pry-byebug'
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
