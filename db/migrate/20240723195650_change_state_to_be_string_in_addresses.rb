class ChangeStateToBeStringInAddresses < ActiveRecord::Migration[7.1]
  def change
    change_column :addresses, :state, :string
  end
end
