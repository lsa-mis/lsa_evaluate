class RemoveKindIndexFromAddressTypes < ActiveRecord::Migration[7.1]
  def change
    remove_index :address_types, name: 'kind_unq_idx'
  end
end
