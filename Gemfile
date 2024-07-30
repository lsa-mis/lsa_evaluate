# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 7.1.3'
ruby '3.3.0'

gem 'actiontext'
gem 'bootsnap', require: false
gem 'cancancan'
gem 'country_select'
gem 'cssbundling-rails'
gem 'devise', '~> 4.9'
gem 'jbuilder'
gem 'jsbundling-rails'
gem 'mysql2', '>= 0.5.3'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'
gem 'puma'
gem 'redis', '~> 4.0'
gem 'sassc-rails'
gem 'simple_form', '~> 5.3'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'web-console'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
end

group :development, :staging do
  gem 'letter_opener_web'
end

group :development, :test do
  gem 'capybara'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'webdrivers'
end

group :development, :staging, :test do
  gem 'faker'
end
