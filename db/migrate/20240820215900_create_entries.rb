class CreateEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :entries do |t|
      t.string :title, null: false
      t.references :status, null: false, foreign_key: true
      t.references :contest_instance, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :entries, :id, unique: true, name: 'id_unq_idx'
    add_index :entries, :status_id, name: 'status_id_idx'
    add_index :entries, :contest_instance_id, name: 'contest_instance_id_idx'
    add_index :entries, :profile_id, name: 'profile_id_idx'
    add_index :entries, :category_id, name: 'category_id_idx'
  end
end
