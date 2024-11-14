# app/models/entry_ranking.rb
class EntryRanking < ApplicationRecord
  belongs_to :entry
  belongs_to :judging_round
  belongs_to :user

  validates :rank, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :entry_id, uniqueness: { scope: [ :judging_round_id, :user_id ] }
  validate :user_must_be_assigned_judge

  private

  def user_must_be_assigned_judge
    unless JudgingAssignment.exists?(user: user, contest_instance: judging_round.contest_instance)
      errors.add(:user, 'must be assigned as judge for this contest')
    end
  end
end
