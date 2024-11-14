# app/models/judging_round.rb
class JudgingRound < ApplicationRecord
  belongs_to :contest_instance
  has_many :entry_rankings, dependent: :destroy
  has_many :entries, through: :entry_rankings

  validates :round_number, presence: true,
            numericality: { greater_than: 0 }
  validates :round_number, uniqueness: { scope: :contest_instance_id }
  validate :dates_are_valid

  private

  def dates_are_valid
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
