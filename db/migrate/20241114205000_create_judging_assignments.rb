class CreateJudgingAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :judging_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contest_instance, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :judging_assignments, [ :user_id, :contest_instance_id ], unique: true
  end
end
