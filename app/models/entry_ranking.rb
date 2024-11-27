# == Schema Information
#
# Table name: entry_rankings
#
#  id                      :bigint           not null, primary key
#  notes                   :text(65535)
#  rank                    :integer
#  selected_for_next_round :boolean          default(FALSE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  entry_id                :bigint           not null
#  judging_round_id        :bigint           not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_entry_rankings_on_entry_id          (entry_id)
#  index_entry_rankings_on_judging_round_id  (judging_round_id)
#  index_entry_rankings_on_user_id           (user_id)
#  index_entry_rankings_uniqueness           (entry_id,judging_round_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (entry_id => entries.id)
#  fk_rails_...  (judging_round_id => judging_rounds.id)
#  fk_rails_...  (user_id => users.id)
#
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
