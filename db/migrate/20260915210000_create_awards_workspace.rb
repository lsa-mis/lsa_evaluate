# frozen_string_literal: true

class CreateAwardsWorkspace < ActiveRecord::Migration[8.1]
  def change
    create_table :awards do |t|
      t.references :container, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false, default: 'primary'
      t.decimal :default_amount, precision: 10, scale: 2
      t.string :default_shortcode
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :awards, [ :container_id, :name ], unique: true
    add_index :awards, [ :container_id, :position ]

    create_table :entry_awards do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :award, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.string :shortcode
      t.text :notes

      t.timestamps
    end

    add_index :entry_awards, [ :entry_id, :award_id ], unique: true

    add_column :entries, :award_status, :string, null: false, default: 'unawarded'
    add_column :entries, :placement, :integer
    add_index :entries, :award_status

    add_column :contest_instances, :award_emails_sent_count, :integer, null: false, default: 0
  end
end
