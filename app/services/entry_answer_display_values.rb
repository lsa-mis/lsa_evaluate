# frozen_string_literal: true

class EntryAnswerDisplayValues
  def initialize(profile:, questions:, submitted_answers: nil)
    @profile = profile
    @questions = questions
    @submitted_answers = submitted_answers || {}
  end

  def call
    values = ApplicationQuestionPrefill.for(profile: @profile, questions: @questions)

    @questions.each do |question|
      next unless submitted_key_present?(question)

      raw = @submitted_answers[question.id.to_s] || @submitted_answers[question.id]
      normalized = EntryAnswerParamNormalizer.normalize(question, raw)

      if normalized.nil?
        values.delete(question.id)
      else
        values[question.id] = normalized
      end
    end

    values
  end

  def self.for(profile:, questions:, submitted_answers: nil)
    new(profile:, questions:, submitted_answers:).call
  end

  private

  def submitted_key_present?(question)
    @submitted_answers.key?(question.id.to_s) || @submitted_answers.key?(question.id)
  end
end
