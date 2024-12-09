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
#  internal_comments       :text(65535)
#  external_comments       :text(65535)
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
  validate :validate_comment_requirements

  private

  def user_must_be_assigned_judge
    unless JudgingAssignment.exists?(user: user, contest_instance: judging_round.contest_instance)
      errors.add(:user, 'must be assigned as judge for this contest')
    end
  end

  def validate_comment_requirements
    if judging_round.require_internal_comments && internal_comments.blank?
      errors.add(:internal_comments, 'are required')
    elsif judging_round.require_internal_comments && judging_round.min_internal_comment_words > 0
      word_count = internal_comments.to_s.split.size
      if word_count < judging_round.min_internal_comment_words
        errors.add(:internal_comments, "must contain at least #{judging_round.min_internal_comment_words} words")
      end
    end

    if judging_round.require_external_comments && external_comments.blank?
      errors.add(:external_comments, 'are required')
    elsif judging_round.require_external_comments && judging_round.min_external_comment_words > 0
      word_count = external_comments.to_s.split.size
      if word_count < judging_round.min_external_comment_words
        errors.add(:external_comments, "must contain at least #{judging_round.min_external_comment_words} words")
      end
    end
  end
end
