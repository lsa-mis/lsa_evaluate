class AddPenNameToEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :pen_name, :string
  end
end
