# frozen_string_literal: true

namespace :profiles do
  desc 'Backfill profile.campus_id from the most recent campus application answer'
  task backfill_campus: :environment do
    updated = ProfileCampusBackfill.call
    puts "Updated campus_id on #{updated} profile#{'s' unless updated == 1}."
  end
end
