class ChangeDepartmentInProfiles < ActiveRecord::Migration[7.2]
  def up
    # Add new department column
    add_column :profiles, :department, :string

    # Remove foreign key constraint on department_id
    remove_foreign_key :profiles, column: :department_id

    # Remove index on department_id
    remove_index :profiles, column: :department_id

    # Remove department_id column
    remove_column :profiles, :department_id
  end

  def down
    # Add department_id column back
    add_column :profiles, :department_id, :bigint

    # Add index on department_id
    add_index :profiles, :department_id

    # Add foreign key constraint back
    add_foreign_key :profiles, :departments, column: :department_id

    # Remove department column
    remove_column :profiles, :department
  end
end
