class CreateJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    create_table :judging_rounds do |t|
      t.references :contest_instance, null: false, foreign_key: true
      t.integer :round_number, null: false
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :active, default: false, null: false
      t.boolean :completed, default: false, null: false
      t.timestamps
    end

    add_index :judging_rounds, [ :contest_instance_id, :round_number ], unique: true
  end
end
