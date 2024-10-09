class RenameDescriptionToNotesInContainers < ActiveRecord::Migration[7.2]
  def change
    rename_column :containers, :description, :notes
  end
end
