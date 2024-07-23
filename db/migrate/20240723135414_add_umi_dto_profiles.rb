class AddUmiDtoProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :umid, :integer, null: false
  end
end
