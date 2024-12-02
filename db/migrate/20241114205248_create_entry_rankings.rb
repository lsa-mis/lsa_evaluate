class CreateEntryRankings < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_rankings do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :judging_round, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rank
      t.text :notes
      t.boolean :selected_for_next_round, default: false, null: false
      t.timestamps
    end

    add_index :entry_rankings, [ :entry_id, :judging_round_id, :user_id ], unique: true, name: 'index_entry_rankings_uniqueness'
  end
end
