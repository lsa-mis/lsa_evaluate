class ConvertUmidToString < ActiveRecord::Migration[7.2]
  def up
    # Add temporary column
    add_column :profiles, :umid_string, :string

    # Copy data with proper formatting
    Profile.find_each do |profile|
      profile.update_column(:umid_string, profile.umid.to_s.rjust(8, '0'))
    end

    # Remove old column and rename new column
    remove_column :profiles, :umid
    rename_column :profiles, :umid_string, :umid

    # Add index back
    add_index :profiles, :umid, unique: true
  end

  def down
    change_column :profiles, :umid, :integer
  end
end
