# frozen_string_literal: true

# Idempotent follow-up for environments that already ran UpdateDepartmentQuestionsAndSeedRackham
# before school help_text was added to that migration.
class AddGraduateSchoolHelpTextToSchoolQuestions < ActiveRecord::Migration[8.1]
  def up
    school_definition = ApplicationQuestion::SYSTEM_QUESTION_DEFINITIONS
                        .find { |definition| definition[:system_key] == 'school' }

    ApplicationQuestion.where(system_key: 'school').find_each do |question|
      question.update_columns(
        help_text: school_definition[:help_text],
        updated_at: Time.current
      )
    end
  end

  def down
    ApplicationQuestion.where(system_key: 'school').find_each do |question|
      question.update_columns(
        help_text: nil,
        updated_at: Time.current
      )
    end
  end
end
