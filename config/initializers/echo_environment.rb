puts "\n=== Current Rails Environment: #{Rails.env} ==="
puts "=== Current Database: #{ActiveRecord::Base.connection_db_config.database} ==="
puts "=== Current Branch: #{`git rev-parse --abbrev-ref HEAD`.chomp} ===\n"