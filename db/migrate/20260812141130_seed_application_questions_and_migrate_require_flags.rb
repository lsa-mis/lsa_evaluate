# frozen_string_literal: true

class SeedApplicationQuestionsAndMigrateRequireFlags < ActiveRecord::Migration[8.1]
  def up
    Container.find_each do |container|
      ApplicationQuestion.seed_system_questions_for!(container)
    end

    ContestInstance.find_each do |instance|
      container = instance.contest_description.container
      questions = container.application_questions.index_by(&:system_key)

      if instance.require_pen_name && questions['pen_name']
        upsert_requirement(instance, questions['pen_name'], 'required')
      end

      if instance.require_campus_employment_info && questions['campus_employee']
        upsert_requirement(instance, questions['campus_employee'], 'required')
      end

      if instance.require_finaid_info
        %w[accepted_financial_aid_notice receiving_financial_aid financial_aid_description].each do |system_key|
          next unless questions[system_key]

          upsert_requirement(instance, questions[system_key], 'required')
        end
      end

      backfill_entry_answers(instance, questions)
    end
  end

  def down
    EntryAnswer.delete_all
    ApplicationQuestionRequirement.delete_all
    ApplicationQuestion.delete_all
  end

  private

  def upsert_requirement(requireable, question, status)
    requirement = ApplicationQuestionRequirement.find_or_initialize_by(
      application_question: question,
      requireable: requireable
    )
    requirement.status = status
    requirement.save!
  end

  def backfill_entry_answers(instance, questions)
    instance.entries.find_each do |entry|
      if questions['pen_name'] && entry.pen_name.present?
        create_answer(entry, questions['pen_name'], entry.pen_name)
      end

      if questions['campus_employee']
        create_answer(entry, questions['campus_employee'], entry.campus_employee)
      end

      if questions['accepted_financial_aid_notice']
        create_answer(entry, questions['accepted_financial_aid_notice'], entry.accepted_financial_aid_notice)
      end

      if questions['receiving_financial_aid']
        create_answer(entry, questions['receiving_financial_aid'], entry.receiving_financial_aid)
      end

      if questions['financial_aid_description'] && entry.financial_aid_description.present?
        create_answer(entry, questions['financial_aid_description'], entry.financial_aid_description)
      end
    end
  end

  def create_answer(entry, question, value)
    EntryAnswer.find_or_create_by!(entry: entry, application_question: question) do |answer|
      answer.value = value
    end
  end
end
