class AddRequireCampusEmploymentInfoToContestInstance < ActiveRecord::Migration[7.2]
  def change
    add_column :contest_instances, :require_campus_employment_info, :boolean, default: false, null: false
  end
end
