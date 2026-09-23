# frozen_string_literal: true

class BulkContestInstanceActivationForm
  include ActiveModel::Model

  attr_accessor :date_open, :confirmed

  validates :date_open, presence: true
  validate :must_be_confirmed

  def confirmed?
    ActiveModel::Type::Boolean.new.cast(confirmed)
  end

  def parsed_date_open
    return date_open if date_open.is_a?(Time) || date_open.is_a?(ActiveSupport::TimeWithZone)
    return date_open.in_time_zone if date_open.is_a?(Date)

    Time.zone.parse(date_open.to_s) if date_open.present?
  end

  private

  def must_be_confirmed
    return if confirmed?

    errors.add(:confirmed, 'must be accepted to proceed with bulk activation')
  end
end
