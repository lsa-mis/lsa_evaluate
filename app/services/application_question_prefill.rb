# frozen_string_literal: true

class ApplicationQuestionPrefill
  PROFILE_SYSTEM_KEY_MAP = {
    'pen_name' => ->(profile) { profile.pen_name },
    'campus_employee' => ->(profile) { profile.campus_employee },
    'accepted_financial_aid_notice' => ->(profile) { profile.accepted_financial_aid_notice },
    'receiving_financial_aid' => ->(profile) { profile.receiving_financial_aid },
    'financial_aid_description' => ->(profile) { profile.financial_aid_description },
    'degree' => ->(profile) { profile.degree },
    'department' => ->(profile) { profile.department },
    'major' => ->(profile) { profile.major },
    'grad_date' => ->(profile) { profile.grad_date&.iso8601 },
    'hometown_publication' => ->(profile) { profile.hometown_publication },
    'campus' => ->(profile) { profile.campus_id },
    'school' => ->(profile) { profile.school_id }
  }.freeze

  def initialize(profile:, questions:)
    @profile = profile
    @questions = questions
  end

  def call
    @questions.each_with_object({}) do |question, memo|
      value = prefill_for(question)
      memo[question.id] = value unless value.nil?
    end
  end

  def self.for(profile:, questions:)
    new(profile: profile, questions: questions).call
  end

  private

  def prefill_for(question)
    if question.system?
      answer = latest_system_answer(question.system_key)
      return answer.value if answer

      PROFILE_SYSTEM_KEY_MAP[question.system_key]&.call(@profile)
    else
      latest_custom_answer(question)&.value || question.default_answer_value
    end
  end

  def latest_system_answer(system_key)
    EntryAnswer
      .joins(:entry, :application_question)
      .where(entries: { profile_id: @profile.id, deleted: false })
      .where(application_questions: { system_key: system_key })
      .order('entries.created_at DESC', 'entry_answers.id DESC')
      .first
  end

  def latest_custom_answer(question)
    EntryAnswer
      .joins(:entry, :application_question)
      .where(entries: { profile_id: @profile.id, deleted: false })
      .where(application_questions: { container_id: question.container_id, key: question.key })
      .order('entries.created_at DESC', 'entry_answers.id DESC')
      .first
  end
end
