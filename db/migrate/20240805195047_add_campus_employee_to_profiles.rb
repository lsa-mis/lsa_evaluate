class AddCampusEmployeeToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :campus_employee, :boolean, default: false, null: false
  end
end
