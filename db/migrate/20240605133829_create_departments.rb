class CreateDepartments < ActiveRecord::Migration[7.1]
  def change
    create_table :departments do |t|
      t.integer :dept_id
      t.text :dept_description

      t.timestamps
    end
  end
end
