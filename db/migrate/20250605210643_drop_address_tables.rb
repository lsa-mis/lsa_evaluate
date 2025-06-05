class DropAddressTables < ActiveRecord::Migration[7.1]
  def up
    # Drop tables in reverse order of dependencies
    drop_table :addresses
    drop_table :address_types
  end

  def down
    # Recreate address_types table
    create_table :address_types do |t|
      t.string :kind, null: false
      t.text :description

      t.timestamps
    end

    add_index :address_types, :kind, unique: true
    add_index :address_types, :id, unique: true, name: 'id_unq_idx'

    # Recreate addresses table
    create_table :addresses do |t|
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.references :address_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :addresses, :id, unique: true, name: 'id_unq_idx'
    add_index :addresses, :address_type_id, name: 'address_type_id_idx'
  end
end
