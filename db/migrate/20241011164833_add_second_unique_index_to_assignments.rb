class AddSecondUniqueIndexToAssignments < ActiveRecord::Migration[7.2]
  def change
    add_index :assignments, [:user_id, :container_id], unique: true
  end
end