class AddUniqueIndexToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_index :assignments, %i[role_id user_id container_id], unique: true,
                                                              name: 'index_assignments_on_role_user_container'
  end
end
