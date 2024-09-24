class RenameFirstAndLastNameInProfiles < ActiveRecord::Migration[7.2]
  def change
    rename_column :profiles, :first_name, :preferred_first_name
    rename_column :profiles, :last_name, :preferred_last_name
  end
end
