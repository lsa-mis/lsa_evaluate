# frozen_string_literal: true

class CreateApplicationQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :application_questions do |t|
      t.references :container, null: false, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.text :help_text
      t.string :field_type, null: false
      t.json :options
      t.integer :position, null: false, default: 0
      t.string :system_key
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :application_questions, %i[container_id key], unique: true
    add_index :application_questions, %i[container_id system_key],
              name: 'index_application_questions_on_container_and_system_key'
  end
end
