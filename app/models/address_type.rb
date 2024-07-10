class CreateAddressTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :address_types do |t|
      t.string :kind, null: false
      t.text :description

      t.timestamps
    end
    add_index :address_types, :id, unique: true, name: :id_unq_idx
    add_index :address_types, :kind, unique: true, name: :kind_unq_idx
  end
end
