# frozen_string_literal: true

class CreateEntryAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_answers do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :application_question, null: false, foreign_key: true
      t.json :value

      t.timestamps
    end

    add_index :entry_answers, %i[entry_id application_question_id], unique: true
  end
end
