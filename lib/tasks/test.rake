namespace :test do
  desc 'Run all tests (RSpec and Jest)'
  task all: :environment do
    puts "\n=== Running RSpec Tests ===\n"
    rspec_success = system('bundle exec rspec')

    puts "\n=== Running Jest Tests ===\n"
    jest_success = system('yarn test')

    if !rspec_success || !jest_success
      puts "\n❌ Tests failed!"
      exit 1
    else
      puts "\n✅ All tests passed!"
    end
  end

  desc 'Run only JavaScript tests'
  task js: :environment do
    puts "\n=== Running Jest Tests ===\n"
    exit 1 unless system('yarn test')
  end

  desc 'Run only RSpec tests'
  task rspec: :environment do
    puts "\n=== Running RSpec Tests ===\n"
    exit 1 unless system('bundle exec rspec --format documentation')
    puts "\n✅ RSpec tests passed!"
  end
end

# Make test:all the default when running just 'rake test'
task test: 'test:all'
