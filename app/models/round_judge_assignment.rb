class RoundJudgeAssignment < ApplicationRecord
  belongs_to :judging_round
  belongs_to :user

  validates :user_id, uniqueness: { scope: :judging_round_id }
  validate :user_must_be_judge
  validate :user_must_be_contest_judge

  private

  def user_must_be_judge
    unless user&.judge?
      errors.add(:user, 'must have judge role')
    end
  end

  def user_must_be_contest_judge
    unless judging_round.contest_instance.judges.include?(user)
      errors.add(:user, 'must be assigned to the contest first')
    end
  end
end
