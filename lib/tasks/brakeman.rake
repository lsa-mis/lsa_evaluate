# frozen_string_literal: true

namespace :brakeman do
  desc "Run Brakeman security scan"
  task :check do
    require 'brakeman'
    result = Brakeman.run app_path: ".", print_report: true
    exit 1 if result.filtered_warnings.any?
  end

  desc "Run Brakeman security scan without failing"
  task :run do
    require 'brakeman'
    Brakeman.run app_path: ".", print_report: true
  end
end
