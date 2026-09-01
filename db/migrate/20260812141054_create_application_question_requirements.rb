# frozen_string_literal: true

class CreateApplicationQuestionRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :application_question_requirements do |t|
      t.references :application_question, null: false, foreign_key: true
      t.references :requireable, polymorphic: true, null: false
      t.string :status, null: false
      t.integer :position

      t.timestamps
    end

    add_index :application_question_requirements,
              %i[requireable_type requireable_id application_question_id],
              unique: true,
              name: 'index_aq_requirements_on_requireable_and_question'
  end
end
