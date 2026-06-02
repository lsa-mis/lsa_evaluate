# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

unless ENV['RAILS_ENV'] == 'production'
  branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
  ENV['RAILS_ENV'] = 'development_feature' if branch == 'evaluate_feature_branch'
end

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
