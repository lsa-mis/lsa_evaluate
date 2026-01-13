# == Schema Information
#
# Table name: round_judge_assignments
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  instructions_sent_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  judging_round_id     :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_round_judge_assignments_on_judging_round_id              (judging_round_id)
#  index_round_judge_assignments_on_judging_round_id_and_user_id  (judging_round_id,user_id) UNIQUE
#  index_round_judge_assignments_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (judging_round_id => judging_rounds.id)
#  fk_rails_...  (user_id => users.id)
#
class RoundJudgeAssignment < ApplicationRecord
  belongs_to :judging_round
  belongs_to :user

  validates :user_id, uniqueness: { scope: :judging_round_id }
  validate :user_must_be_judge
  validate :user_must_be_contest_judge

  scope :active, -> { where(active: true) }

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
