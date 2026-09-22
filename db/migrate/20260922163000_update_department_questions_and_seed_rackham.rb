# frozen_string_literal: true

class UpdateDepartmentQuestionsAndSeedRackham < ActiveRecord::Migration[8.1]
  def up
    School.find_or_create_by!(name: School::RACKHAM_NAME)

    department_definition = ApplicationQuestion::SYSTEM_QUESTION_DEFINITIONS
                            .find { |definition| definition[:system_key] == 'department' }
    major_definition = ApplicationQuestion::SYSTEM_QUESTION_DEFINITIONS
                       .find { |definition| definition[:system_key] == 'major' }
    school_definition = ApplicationQuestion::SYSTEM_QUESTION_DEFINITIONS
                        .find { |definition| definition[:system_key] == 'school' }

    ApplicationQuestion.where(system_key: 'department').find_each do |question|
      question.update_columns(
        field_type: department_definition[:field_type],
        label: department_definition[:label],
        options: department_definition[:options],
        updated_at: Time.current
      )
    end

    ApplicationQuestion.where(system_key: 'major').find_each do |question|
      question.update_columns(
        label: major_definition[:label],
        updated_at: Time.current
      )
    end

    ApplicationQuestion.where(system_key: 'school').find_each do |question|
      question.update_columns(
        help_text: school_definition[:help_text],
        updated_at: Time.current
      )
    end
  end

  def down
    ApplicationQuestion.where(system_key: 'department').find_each do |question|
      question.update_columns(
        field_type: 'string',
        label: 'Department (if graduate)',
        options: nil,
        updated_at: Time.current
      )
    end

    ApplicationQuestion.where(system_key: 'major').find_each do |question|
      question.update_columns(
        label: 'Major (if undergraduate)',
        updated_at: Time.current
      )
    end

    ApplicationQuestion.where(system_key: 'school').find_each do |question|
      question.update_columns(
        help_text: nil,
        updated_at: Time.current
      )
    end
  end
end
