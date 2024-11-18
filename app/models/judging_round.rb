# == Schema Information
#
# Table name: judging_rounds
#
#  id                  :bigint           not null, primary key
#  contest_instance_id :bigint           not null
#  round_number        :integer          not null
#  start_date          :datetime
#  end_date            :datetime
#  active              :boolean          default(FALSE), not null
#  completed           :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# app/models/judging_round.rb
class JudgingRound < ApplicationRecord
  belongs_to :contest_instance
  has_many :entry_rankings, dependent: :destroy
  has_many :entries, through: :entry_rankings
  has_many :round_judge_assignments, dependent: :destroy
  has_many :judges, through: :round_judge_assignments, source: :user

  validates :round_number, presence: true,
            numericality: { greater_than: 0 }
  validates :round_number, uniqueness: { scope: :contest_instance_id }
  validate :dates_are_valid
  validate :start_date_after_previous_round

  def assign_judge(user)
    return false unless user.judge?
    round_judge_assignments.create(user: user)
  end

  private

  def dates_are_valid
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end

  def start_date_after_previous_round
    return unless start_date && contest_instance

    previous_round = contest_instance.judging_rounds
                      .where('round_number < ?', round_number)
                      .order(round_number: :desc)
                      .first

    if previous_round&.end_date && start_date < previous_round.end_date
      errors.add(:start_date, "must be after the previous round's end date (#{I18n.l(previous_round.end_date, format: :long)})")
    end
  end
end
