source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "rails", "~> 7.1.3"
ruby "3.3.0"

gem "bootsnap", require: false
gem "cssbundling-rails"
gem "jbuilder"
gem "jsbundling-rails"
gem "pg", "~> 1.1"
gem "puma"
gem "redis", "~> 4.0"
gem 'sassc-rails'
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "web-console"
end

group :development, :test do
  gem "capybara"
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem 'pry-rails'
  gem "pry-byebug"
  gem "webdrivers"
end

group :development, :staging do
  gem "letter_opener_web"
end

group :development, :staging, :test do
  gem "faker"
end