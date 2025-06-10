class RemoveAddressColumnsFromProfiles < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :profiles, :addresses, column: :home_address_id
    remove_foreign_key :profiles, :addresses, column: :campus_address_id
    remove_column :profiles, :home_address_id, :bigint
    remove_column :profiles, :campus_address_id, :bigint
  end
end
