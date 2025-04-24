namespace :security do
  desc 'Run security checks on dependencies'
  task :audit do
    puts 'Running bundle audit...'
    system('bundle audit check --update')

    puts 'Checking for outdated dependencies...'
    system('bundle outdated')

    puts 'Checking for vulnerable gems...'
    system('bundle exec brakeman -A')
  end

  desc 'Update dependencies with security patches'
  task :update do
    puts 'Updating dependencies...'
    system('bundle update')

    puts 'Running security audit after update...'
    Rake::Task['security:audit'].invoke
  end
end
