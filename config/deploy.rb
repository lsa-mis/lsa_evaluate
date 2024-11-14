# config valid for current version and patch releases of Capistrano
lock '~> 3.19.1'

set :default_env, {
  'NODE_OPTIONS' => '--openssl-legacy-provider',
  'PATH' => '$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH',
  'SKIP_ECHO_ENV' => 'true',
  'SKIP_SEEDS' => 'true'
}

SSHKit.config.command_map[:bundle] = '/home/deployer/.asdf/shims/bundle'
SSHKit.config.command_map[:ruby] = '/home/deployer/.asdf/shims/ruby'

server 'evaluateprod.miserver.it.umich.edu', roles: %w[app db web], primary: true

set :application, 'evaluate'
set :repo_url, 'git@github.com:lsa-mis/lsa_evaluate.git'
set :user, 'deployer'
set :branch, 'main'

# Don't change these unless you know what you're doing
set :pty,             true
set :stage,           :production
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w[~/.ssh/id_ed25519.pub] }
set :tmp_dir, '/home/deployer/tmp'
set :keep_releases, 3

# Default value for :linked_files and linked_dirs is []
set :linked_files, %w[config/puma.rb config/nginx.conf config/master.key config/lsa-was-base-efc3d7203bbd.json]
set :linked_dirs,  %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

namespace :puma do
  desc 'Stop the PUMA service'
  task :stop do
    on roles(:app) do
      execute "cd #{fetch(:deploy_to)}/current; bin/bundle exec pumactl -P ~/apps/#{fetch(:application)}/current/tmp/pids/puma.pid stop"
    end
  end

  desc 'Restart the PUMA service'
  task :restart do
    on roles(:app) do
      execute "cd #{fetch(:deploy_to)}/current; bin/bundle exec pumactl -P ~/apps/#{fetch(:application)}/current/tmp/pids/puma.pid restart"
    end
  end

  desc 'Start the PUMA service'
  task :start do
    on roles(:app) do
      puts 'You must intially start the puma service using sudo on the server'
    end
  end
end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/main`
        puts 'WARNING: HEAD is not the same as origin/main'
        puts 'Run `git push` to sync changes.'
        exit
      end
    end
  end

  desc 'Upload to shared/config'
  task :upload do
    on roles (:app) do
     upload! 'config/master.key',  "#{fetch(:deploy_to)}/shared/config/master.key"
     upload! 'config/puma_prod.rb',  "#{fetch(:deploy_to)}/shared/config/puma.rb"
     upload! 'config/nginx_prod.conf',  "#{fetch(:deploy_to)}/shared/config/nginx.conf"
     upload! 'config/lsa-was-base-efc3d7203bbd.json',  "#{fetch(:deploy_to)}/shared/config/lsa-was-base-efc3d7203bbd.json"
    end
  end

  before 'bundler:install', 'debug:print_ruby_version'
  before :starting,     :check_revision
  after  :finishing,    'puma:restart'
end

namespace :debug do
  desc 'Print Ruby version, Ruby path, asdf Ruby list, and Rails version'
  task :print_versions do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          # Capture the output of each command
          ruby_version = capture(:ruby, '-v')
          which_ruby = capture(:which, 'ruby')
          asdf_ruby_list = capture(:asdf, 'list ruby')
          rails_version = capture(:bundle, 'exec rails -v')

          # Log the captured outputs
          info "Ruby Version: #{ruby_version.strip}"
          info "Ruby Path: #{which_ruby.strip}"
          info "asdf Ruby Versions: #{asdf_ruby_list.strip}"
          info "Rails Version: #{rails_version.strip}"
        end
      end
    end
  end
end

namespace :maintenance do
  desc 'Maintenance start (edit config/maintenance_template.yml to provide parameters)'
  task :start do
    on roles(:web) do
      upload! 'config/maintenance_template.yml', "#{current_path}/tmp/maintenance.yml"
    end
  end

  desc 'Maintenance stop'
  task :stop do
    on roles(:web) do
      execute "rm #{current_path}/tmp/maintenance.yml"
    end
  end
end
