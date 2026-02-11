namespace :test do
  def run_test(name, command)
    puts "\n=== Running #{name} ===\n"
    success = system(command)
    puts "\n#{success ? '✅' : '❌'} - #{name} #{success ? 'passed' : 'failed'}"
    success
  end

  desc 'Run all tests (RSpec, Jest, and Brakeman)'
  task all: :environment do
    rspec_success = run_test('RSpec Tests', 'bundle exec rspec')
    jest_success = run_test('Jest Tests', 'yarn test')
    brakeman_success = run_test('Brakeman Security Scan', 'bundle exec rake brakeman:run')

    puts "\n================================================"
    puts rspec_success ? "\n✅ RSpec Tests passed!" : "\n❌ RSpec Tests failed!"
    puts jest_success ? "\n✅ Jest Tests passed!" : "\n❌ Jest Tests failed!"
    puts brakeman_success ? "\n✅ Brakeman Security Scan passed!" : "\n❌ Brakeman Security Scan failed!"
    puts "\n================================================"
    puts "\n❌ Tests failed!" unless rspec_success && jest_success && brakeman_success
    exit 1 unless rspec_success && jest_success && brakeman_success
  end

  desc 'Run only JavaScript tests'
  task js: :environment do
    run_test('Jest Tests', 'yarn test') || exit(1)
  end

  desc 'Run only RSpec tests'
  task rspec: :environment do
    run_test('RSpec Tests', 'bundle exec rspec --format documentation') || exit(1)
  end

  desc 'Run only Brakeman security scan'
  task brakeman: :environment do
    run_test('Brakeman Security Scan', 'bundle exec rake brakeman:run') || exit(1)
  end
end

# Make test:all the default when running just 'rake test'
task test: 'test:all'
