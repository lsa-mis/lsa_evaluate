class AddUniqueIndexToProfilesUmid < ActiveRecord::Migration[7.2]
  def up
    # Add a unique index to the umid column
    add_index :profiles, :umid, unique: true
  end

  def down
    # Remove the unique index from the umid column
    remove_index :profiles, :umid
  end
end
