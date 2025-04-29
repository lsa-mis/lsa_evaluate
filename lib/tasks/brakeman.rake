# frozen_string_literal: true

namespace :brakeman do
  desc 'Run Brakeman security scanner'
  task :run do
    require 'brakeman'

    # Create a new tracker and scan the Rails application
    tracker = Brakeman.run(
      app_path: Rails.root.to_s,
      config_file: Rails.root.join('config', 'brakeman.yml').to_s,
      interactive: false,
      print_report: true
    )

    # Exit with non-zero status if warnings found
    # Uncomment the next line if you want to enforce zero warnings in CI
    # exit tracker.warnings.length
  end

  desc 'Run Brakeman and fail if warnings found (for CI/CD)'
  task :check do
    require 'brakeman'

    result = Brakeman.run(
      app_path: Rails.root.to_s,
      config_file: Rails.root.join('config', 'brakeman.yml').to_s,
      interactive: false,
      print_report: true
    )

    # Exit with non-zero status if warnings found
    exit result.warnings.length
  end
end
