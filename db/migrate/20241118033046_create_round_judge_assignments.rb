class CreateRoundJudgeAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :round_judge_assignments do |t|
      t.references :judging_round, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :round_judge_assignments, [ :judging_round_id, :user_id ], unique: true
  end
end
