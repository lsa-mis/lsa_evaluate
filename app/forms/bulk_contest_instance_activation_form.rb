# frozen_string_literal: true

class BulkContestInstanceActivationForm
  include ActiveModel::Model

  attr_accessor :date_open, :confirmed

  validates :date_open, presence: true
  validate :must_be_confirmed
  validate :date_open_must_be_parseable

  def confirmed?
    ActiveModel::Type::Boolean.new.cast(confirmed)
  end

  def parsed_date_open
    return date_open if date_open.is_a?(Time) || date_open.is_a?(ActiveSupport::TimeWithZone)
    return date_open.in_time_zone if date_open.is_a?(Date)
    return if date_open.blank?

    Time.zone.parse(date_open.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  private

  def must_be_confirmed
    return if confirmed?

    errors.add(:confirmed, 'must be accepted to proceed with bulk activation')
  end

  def date_open_must_be_parseable
    return if date_open.blank?
    return if date_open.is_a?(Time) || date_open.is_a?(ActiveSupport::TimeWithZone) || date_open.is_a?(Date)

    parsed = Time.zone.parse(date_open.to_s)
    errors.add(:date_open, 'is not a valid date') if parsed.nil?
  rescue ArgumentError, TypeError
    errors.add(:date_open, 'is not a valid date')
  end
end
