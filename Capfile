require 'stringio'
# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Include tasks from other gems included in your Gemfile

require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/asdf'
# require 'capistrano/sidekiq'
# install_plugin Capistrano::Sidekiq
# install_plugin Capistrano::Sidekiq::Systemd

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
