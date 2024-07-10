class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name, default: '', null: false
      t.string :last_name, default: '', null: false
      t.references :class_level, foreign_key: true
      t.references :school, foreign_key: true
      t.references :campus, foreign_key: true
      t.string :major
      t.references :department, foreign_key: true
      t.date :grad_date, null: false
      t.string :degree, null: false
      t.boolean :receiving_financial_aid, default: false, null: false
      t.boolean :accepted_financial_aid_notice, default: false, null: false
      t.text :financial_aid_description
      t.string :hometown_publication
      t.string :pen_name
      t.references :address, foreign_key: true

      t.timestamps
    end

    add_index :profiles, :id, unique: true, name: 'id_unq_idx'
    add_index :profiles, :user_id, name: 'user_id_idx'
    add_index :profiles, :class_level_id, name: 'class_level_id_idx'
    add_index :profiles, :school_id, name: 'school_id_idx'
    add_index :profiles, :campus_id, name: 'campus_id_idx'
    add_index :profiles, :address_id, name: 'address_id_idx'
  end
end
