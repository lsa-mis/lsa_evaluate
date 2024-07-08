class CreateContestInstances < ActiveRecord::Migration[7.1]
  def change
    create_table :contest_instances do |t|
      t.references :status, null: false, foreign_key: true
      t.references :contest_description, null: false, foreign_key: true
      t.datetime :date_open, null: false
      t.datetime :date_closed, null: false
      t.text :notes
      t.boolean :judging_open, default: false, null: false
      t.integer :judging_rounds, default: 1
      t.references :category, null: false, foreign_key: true
      t.boolean :has_course_requirement, default: false, null: false
      t.boolean :judge_evaluations_complete, default: false, null: false
      t.text :course_requirement_description
      t.boolean :recletter_required, default: false, null: false
      t.boolean :transcript_required, default: false, null: false
      t.integer :maximum_number_entries_per_applicant, default: 1, null: false
      t.string :created_by

      t.timestamps
    end

    add_index :contest_instances, :id, unique: true, name: 'id_unq_idx'
    add_index :contest_instances, :status_id, name: 'status_id_idx'
    add_index :contest_instances, :contest_description_id, name: 'contest_description_id_idx'
    add_index :contest_instances, :category_id, name: 'category_id_idx'
  end
end
