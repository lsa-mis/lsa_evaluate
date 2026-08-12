# frozen_string_literal: true

class ApplicationQuestion < ApplicationRecord
  FIELD_TYPES = %w[
    string text boolean date select select_with_other campus school
  ].freeze

  AGREEMENT_SYSTEM_KEYS = %w[
    accepted_financial_aid_notice
    submission_acknowledgement_agreement
  ].freeze

  SYSTEM_QUESTION_DEFINITIONS = [
    { system_key: 'pen_name', key: 'pen_name', label: 'Pen name', field_type: 'string',
      help_text: 'The pen name should bear no resemblance to your real name or any other personal information.' },
    { system_key: 'campus_employee', key: 'campus_employee', label: 'Are you a campus employee?', field_type: 'boolean' },
    { system_key: 'accepted_financial_aid_notice', key: 'accepted_financial_aid_notice',
      label: 'I accept the financial aid notice', field_type: 'boolean' },
    { system_key: 'receiving_financial_aid', key: 'receiving_financial_aid',
      label: 'Are you receiving financial aid?', field_type: 'boolean' },
    { system_key: 'financial_aid_description', key: 'financial_aid_description',
      label: 'Financial aid description', field_type: 'text' },
    { system_key: 'degree', key: 'degree', label: 'Degree', field_type: 'string' },
    { system_key: 'department', key: 'department', label: 'Department (if graduate)', field_type: 'string' },
    { system_key: 'major', key: 'major', label: 'Major (if undergraduate)', field_type: 'string' },
    { system_key: 'grad_date', key: 'grad_date', label: 'Expected graduation date', field_type: 'date' },
    { system_key: 'hometown_publication', key: 'hometown_publication',
      label: 'Hometown newspaper or preferred media outlet', field_type: 'string' },
    { system_key: 'campus', key: 'campus', label: 'Primary campus class location', field_type: 'campus' },
    { system_key: 'school', key: 'school', label: 'School or college', field_type: 'school' },
    { system_key: 'contest_referral_source', key: 'contest_referral_source',
      label: 'How did you hear about this contest?', field_type: 'select_with_other',
      options: { choices: [ 'Faculty', 'Advisor', 'Friend', 'Website', 'Social media', 'Other' ] } },
    { system_key: 'submission_sole_author', key: 'submission_sole_author',
      label: 'I am the sole author of this submission', field_type: 'boolean' },
    { system_key: 'submission_acknowledgement_agreement', key: 'submission_acknowledgement_agreement',
      label: 'I agree to the submission acknowledgement', field_type: 'boolean' }
  ].freeze

  belongs_to :container
  has_many :application_question_requirements, dependent: :destroy
  has_many :entry_answers, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: { scope: :container_id }
  validates :label, presence: true
  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }
  validates :system_key, uniqueness: { scope: :container_id }, allow_nil: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :field_type_immutable_after_create, on: :update
  validate :system_key_immutable_after_create, on: :update
  validate :cannot_deactivate_when_required_by_active_instance, on: :update

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :system, -> { where.not(system_key: nil) }
  scope :custom, -> { where(system_key: nil) }

  before_validation :normalize_key
  before_destroy :prevent_destroy_with_answers

  def system?
    system_key.present?
  end

  def custom?
    !system?
  end

  def agreement?
    AGREEMENT_SYSTEM_KEYS.include?(system_key)
  end

  def self.seed_system_questions_for!(container)
    SYSTEM_QUESTION_DEFINITIONS.each_with_index do |definition, index|
      question = container.application_questions.find_or_initialize_by(system_key: definition[:system_key])
      question.assign_attributes(
        key: definition[:key],
        label: definition[:label],
        help_text: definition[:help_text],
        field_type: definition[:field_type],
        options: definition[:options],
        position: index,
        active: true
      )
      question.save!
    end
  end

  private

  def normalize_key
    self.key = key.to_s.parameterize(separator: '_') if key.present?
  end

  def field_type_immutable_after_create
    errors.add(:field_type, 'cannot be changed after create') if will_save_change_to_field_type?
  end

  def system_key_immutable_after_create
    errors.add(:system_key, 'cannot be changed after create') if will_save_change_to_system_key?
  end

  def cannot_deactivate_when_required_by_active_instance
    return unless will_save_change_to_active? && !active
    return unless system?

    required_on_active_instance = ApplicationQuestionRequirement
      .where(application_question_id: id, requireable_type: 'ContestInstance', status: 'required')
      .joins("INNER JOIN contest_instances ON contest_instances.id = application_question_requirements.requireable_id AND application_question_requirements.requireable_type = 'ContestInstance'")
      .where(contest_instances: { active: true })
      .exists?

    container_required = application_question_requirements.exists?(requireable: container, status: 'required')
    has_active_instances = ContestInstance
      .joins(contest_description: :container)
      .where(active: true, contest_descriptions: { container_id: container_id })
      .exists?

    if required_on_active_instance || (container_required && has_active_instances)
      errors.add(:active, 'cannot be deactivated while required by an active contest instance')
    end
  end

  def prevent_destroy_with_answers
    return unless entry_answers.exists?

    errors.add(:base, 'cannot delete a question that has answers; deactivate it instead')
    throw :abort
  end
end
