class RemoveAddressIdFromProfiles < ActiveRecord::Migration[7.1]
  def change
    remove_column :profiles, :address_id, :bigint
  end
end
