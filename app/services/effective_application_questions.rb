# frozen_string_literal: true

class EffectiveApplicationQuestions
  EffectiveQuestion = Struct.new(:question, :status, :source_level, keyword_init: true)

  LEVEL_ORDER = {
    'Container' => 1,
    'ContestDescription' => 2,
    'ContestInstance' => 3
  }.freeze

  def initialize(contest_instance)
    @contest_instance = contest_instance
    @contest_description = contest_instance.contest_description
    @container = @contest_description.container
  end

  def call
    questions = @container.application_questions.active.ordered.includes(:application_question_requirements)
    requirements_by_question = load_requirements.index_by { |r| [r.application_question_id, r.requireable_type] }

    questions.filter_map do |question|
      resolved = resolve_status(question, requirements_by_question)
      next if resolved.nil? || resolved[:status] == 'off'

      EffectiveQuestion.new(
        question: question,
        status: resolved[:status],
        source_level: resolved[:source_level]
      )
    end
  end

  def self.for(contest_instance)
    new(contest_instance).call
  end

  private

  def load_requirements
    question_ids = @container.application_question_ids
    return ApplicationQuestionRequirement.none if question_ids.empty?

    ApplicationQuestionRequirement.where(application_question_id: question_ids).where(
      "(requireable_type = 'Container' AND requireable_id = :container_id) OR
       (requireable_type = 'ContestDescription' AND requireable_id = :description_id) OR
       (requireable_type = 'ContestInstance' AND requireable_id = :instance_id)",
      container_id: @container.id,
      description_id: @contest_description.id,
      instance_id: @contest_instance.id
    )
  end

  def resolve_status(question, requirements_by_question)
    resolved = nil

    %w[Container ContestDescription ContestInstance].each do |level|
      requirement = requirements_by_question[[question.id, level]]
      next unless requirement

      resolved = { status: requirement.status, source_level: level }
    end

    resolved
  end
end
