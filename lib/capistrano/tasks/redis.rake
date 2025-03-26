namespace :redis do
  desc 'Check if Redis is installed'
  task :check do
    on roles(:app) do
      unless test('which redis-server')
        error 'Redis is not installed. Please install Redis before deploying.'
        exit 1
      end
    end
  end

  desc 'Install Redis'
  task :install do
    on roles(:app) do
      execute :sudo, 'apt-get update'
      execute :sudo, 'apt-get install -y redis-server'
      execute :sudo, 'systemctl enable redis-server'
      execute :sudo, 'systemctl start redis-server'
    end
  end
end

# Hook into the deployment flow
before 'deploy:check', 'redis:check'
