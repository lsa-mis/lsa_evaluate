# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

unless ENV['RAILS_ENV'] == 'production'
  ENV['RAILS_ENV'] = 'development_feature' if `git rev-parse --abbrev-ref HEAD`.chomp == 'evaluate_feature_branch'
end

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
