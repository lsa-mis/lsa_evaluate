class ChangeCountryToBeStringInAddresses < ActiveRecord::Migration[7.1]
  def change
    change_column :addresses, :country, :string
  end
end
