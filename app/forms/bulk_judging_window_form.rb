# frozen_string_literal: true

class BulkJudgingWindowForm
  include ActiveModel::Model

  attr_accessor :end_date, :start_date, :update_start_date, :cascade_following_rounds, :cascade_mode

  validates :end_date, presence: true
  validate :end_date_after_start_date, if: -> { update_start_date.present? && start_date.present? }
  validate :reasonable_dates

  def parsed_end_date
    Time.zone.parse(end_date.to_s)
  end

  def parsed_start_date
    return nil if start_date.blank?

    Time.zone.parse(start_date.to_s)
  end

  def cascade_enabled?
    ActiveModel::Type::Boolean.new.cast(cascade_following_rounds)
  end

  def update_start_date?
    ActiveModel::Type::Boolean.new.cast(update_start_date)
  end

  def cascade_mode_symbol
    (cascade_mode.presence || 'minimum_bump').to_sym
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if parsed_end_date < parsed_start_date
      errors.add(:end_date, 'must be after start date')
    end
  end

  def reasonable_dates
    if end_date.present? && parsed_end_date.nil?
      errors.add(:end_date, 'is not a valid date')
    elsif end_date.present? && parsed_end_date.year > 2100
      errors.add(:end_date, 'is not a valid date')
    end

    return unless update_start_date? && start_date.present?

    if parsed_start_date.nil?
      errors.add(:start_date, 'is not a valid date')
    elsif parsed_start_date.year > 2100
      errors.add(:start_date, 'is not a valid date')
    end
  end
end
