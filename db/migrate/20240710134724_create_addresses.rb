# db/migrate/XXXX_create_addresses.rb
class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses do |t|
      t.string :address1
      t.string :address2
      t.string :city
      t.integer :state
      t.string :zip
      t.string :phone
      t.integer :country
      t.references :address_type, foreign_key: true

      t.timestamps
    end

    add_index :addresses, :id, unique: true, name: :id_unq_idx
    add_index :addresses, :address_type_id, name: :address_type_id_idx
  end
end
