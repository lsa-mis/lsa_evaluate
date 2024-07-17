class AddUniqueIndexToAddressTypes < ActiveRecord::Migration[7.1]
  def change
    add_index :address_types, :kind, unique: true
  end
end
