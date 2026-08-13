# frozen_string_literal: true

class EntryAnswer < ApplicationRecord
  belongs_to :entry
  belongs_to :application_question

  validates :application_question_id, uniqueness: { scope: :entry_id }

  def display_value
    case application_question.field_type
    when 'boolean'
      ActiveModel::Type::Boolean.new.cast(raw_scalar) ? 'Yes' : 'No'
    when 'campus'
      Campus.find_by(id: raw_scalar)&.campus_descr || raw_scalar.to_s
    when 'school'
      School.find_by(id: raw_scalar)&.name || raw_scalar.to_s
    when 'select_with_other'
      if value.is_a?(Hash)
        choice = value['choice'] || value[:choice]
        other = value['other'] || value[:other]
        choice == 'Other' && other.present? ? "Other: #{other}" : choice.to_s
      else
        raw_scalar.to_s
      end
    when 'date'
      raw_scalar.to_s
    else
      raw_scalar.to_s
    end
  end

  def blank_answer?
    case application_question.field_type
    when 'boolean'
      value.nil?
    when 'select_with_other'
      if value.is_a?(Hash)
        choice = value['choice'] || value[:choice]
        other = value['other'] || value[:other]
        choice.blank? || (choice == 'Other' && other.blank?)
      else
        raw_scalar.blank?
      end
    else
      raw_scalar.blank?
    end
  end

  def agreement_accepted?
    ActiveModel::Type::Boolean.new.cast(raw_scalar) == true
  end

  private

  def raw_scalar
    return value['value'] if value.is_a?(Hash) && value.key?('value')
    return value[:value] if value.is_a?(Hash) && value.key?(:value)

    value
  end
end
