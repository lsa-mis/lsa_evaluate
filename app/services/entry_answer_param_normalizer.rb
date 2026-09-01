# frozen_string_literal: true

class EntryAnswerParamNormalizer
  def self.normalize(question, raw)
    new(question, raw).normalize
  end

  def initialize(question, raw)
    @question = question
    @raw = raw
  end

  def normalize
    case @question.field_type
    when 'boolean'
      return nil if @raw.nil? || @raw == ''

      ActiveModel::Type::Boolean.new.cast(@raw)
    when 'select_with_other'
      return nil if @raw.nil?

      if @raw.is_a?(ActionController::Parameters) || @raw.is_a?(Hash)
        hash = @raw.respond_to?(:to_unsafe_h) ? @raw.to_unsafe_h : @raw.to_h
        hash.slice('choice', 'other', :choice, :other).stringify_keys
      else
        { 'choice' => @raw }
      end
    when 'campus', 'school'
      @raw.presence&.to_i
    when 'date'
      @raw.presence
    else
      @raw.presence
    end
  end
end
