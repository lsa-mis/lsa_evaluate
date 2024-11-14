puts "Current Rails Environment: #{Rails.env}"
puts "Database: #{ActiveRecord::Base.connection_db_config.database}"
