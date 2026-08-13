# frozen_string_literal: true

module ApplicationQuestionRequirementsSync
  extend ActiveSupport::Concern

  private

  def sync_application_question_requirements!(requireable, requirements_params)
    return if requirements_params.blank?

    requirements_params.each do |question_id, attrs|
      attrs = attrs.to_unsafe_h if attrs.respond_to?(:to_unsafe_h)
      status = attrs['status'].presence || attrs[:status].presence
      question = ApplicationQuestion.find_by(id: question_id)
      next unless question
      next unless question.container_id == requireable_container_id(requireable)

      if status.blank? || status == 'inherit'
        ApplicationQuestionRequirement.where(
          application_question: question,
          requireable: requireable
        ).destroy_all
        next
      end

      requirement = ApplicationQuestionRequirement.find_or_initialize_by(
        application_question: question,
        requireable: requireable
      )
      requirement.status = status
      requirement.position = attrs['position'].presence || attrs[:position]
      requirement.save!
    end
  end

  def requireable_container_id(requireable)
    case requireable
    when Container then requireable.id
    when ContestDescription then requireable.container_id
    when ContestInstance then requireable.contest_description.container_id
    end
  end
end
