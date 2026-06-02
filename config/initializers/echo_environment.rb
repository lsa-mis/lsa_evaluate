unless Rails.env.production? || ENV['SKIP_ECHO_ENV']
  puts "\n=== Current Rails Environment: #{Rails.env} ==="
  puts "=== Current Database: #{ActiveRecord::Base.connection_db_config.database} ==="
  branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
  branch = ENV["HATCHBOX_BRANCH"].presence || "unknown" if branch.blank?

  puts "=== Current Branch: #{branch} ===\n"
end
