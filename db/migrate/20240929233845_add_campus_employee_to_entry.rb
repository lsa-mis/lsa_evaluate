class AddCampusEmployeeToEntry < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :campus_employee, :boolean, default: false, null: false
  end
end
