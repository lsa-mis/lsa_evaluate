class AddNameToDepartmentsAndMakeDeptIdNotNull < ActiveRecord::Migration[7.1]
  def change
    add_column :departments, :name, :string

    change_column_null :departments, :dept_id, false
  end
end
