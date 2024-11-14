# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

ENV['RAILS_ENV'] = 'development_feature' if `git rev-parse --abbrev-ref HEAD`.chomp == 'evaluate_feature_branch'

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
