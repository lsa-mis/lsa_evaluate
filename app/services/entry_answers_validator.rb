# frozen_string_literal: true

class EntryAnswersValidator
  attr_reader :built_answers

  def initialize(entry:, effective_questions:, answers_params:)
    @entry = entry
    @effective_questions = effective_questions
    @answers_params = answers_params || {}
    @built_answers = []
  end

  def call
    @effective_questions.each do |effective|
      question = effective.question
      raw = @answers_params[question.id.to_s] || @answers_params[question.id]
      normalized = normalize_value(question, raw)
      answer = EntryAnswer.new(application_question: question, value: normalized)
      @built_answers << answer

      next unless effective.status == 'required'
      next unless question.applies_to_class_level?(class_level_for_validation)

      if question.agreement?
        unless answer.agreement_accepted?
          @entry.errors.add(:base, "#{question.label} must be accepted for this contest")
        end
      elsif answer.blank_answer?
        @entry.errors.add(:base, "#{question.label} can't be blank for this contest")
      end
    end

    @entry.errors.empty?
  end

  private

  def class_level_for_validation
    @class_level_for_validation ||= ClassLevel.find_by(id: @entry.profile.class_level_id)
  end

  def normalize_value(question, raw)
    case question.field_type
    when 'boolean'
      cast = ActiveModel::Type::Boolean.new.cast(raw)
      cast.nil? ? false : cast
    when 'select_with_other'
      return nil if raw.nil?

      if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.slice('choice', 'other', :choice, :other).stringify_keys
      else
        { 'choice' => raw }
      end
    when 'campus', 'school'
      raw.presence&.to_i
    when 'date'
      raw.presence
    else
      raw.presence
    end
  end
end
