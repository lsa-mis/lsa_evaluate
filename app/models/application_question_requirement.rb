# frozen_string_literal: true

class ApplicationQuestionRequirement < ApplicationRecord
  STATUSES = %w[required optional off].freeze
  REQUIREABLE_TYPES = %w[Container ContestDescription ContestInstance].freeze

  belongs_to :application_question
  belongs_to :requireable, polymorphic: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :requireable_type, inclusion: { in: REQUIREABLE_TYPES }
  validates :application_question_id, uniqueness: { scope: %i[requireable_type requireable_id] }
  validate :question_belongs_to_requireable_container

  private

  def question_belongs_to_requireable_container
    return if application_question.blank? || requireable.blank?

    container = case requireable
                when Container then requireable
                when ContestDescription then requireable.container
                when ContestInstance then requireable.contest_description.container
                end

    return if container && application_question.container_id == container.id

    errors.add(:application_question, 'must belong to the same container')
  end
end
