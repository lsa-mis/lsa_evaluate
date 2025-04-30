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
    brakeman_success = run_test('Brakeman Security Scan', 'bundle exec brakeman')

    puts "\n================================================"
    puts "\n✅ RSpec Tests passed!" if rspec_success else puts "\n❌ RSpec Tests failed!"
    puts "\n✅ Jest Tests passed!" if jest_success else puts "\n❌ Jest Tests failed!"
    puts "\n✅ Brakeman Security Scan passed!" if brakeman_success else puts "\n❌ Brakeman Security Scan failed!"
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
    run_test('Brakeman Security Scan', 'bundle exec brakeman') || exit(1)
  end
end

# Make test:all the default when running just 'rake test'
task test: 'test:all'
