class RemovePhoneFromAddresses < ActiveRecord::Migration[7.2]
  def change
    remove_column :addresses, :phone, :string
  end
end
