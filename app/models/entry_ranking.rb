# == Schema Information
#
# Table name: entry_rankings
#
#  id                      :bigint           not null, primary key
#  external_comments       :text(65535)
#  finalized               :boolean          default(FALSE), not null
#  internal_comments       :text(65535)
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

  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :entry_id, uniqueness: {
    scope: [ :judging_round_id, :user_id ],
    message: 'has already been ranked by this judge in this round'
  }
  validate :user_must_be_assigned_judge
  validate :comments_validation, if: :finalized?

  private

  def user_must_be_assigned_judge
    unless user&.judge_for?(judging_round.contest_instance)
      errors.add(:user, 'must be an assigned judge for this contest')
    end
  end

  def comments_validation
    if judging_round.require_internal_comments && internal_comments.blank?
      errors.add(:internal_comments, 'are required')
    end

    if judging_round.require_external_comments && external_comments.blank?
      errors.add(:external_comments, 'are required')
    end

    if judging_round.min_internal_comment_words.positive? && internal_comments.present?
      word_count = internal_comments.split.length
      if word_count < judging_round.min_internal_comment_words
        errors.add(:internal_comments, "must be at least #{judging_round.min_internal_comment_words} words")
      end
    end

    if judging_round.min_external_comment_words.positive? && external_comments.present?
      word_count = external_comments.split.length
      if word_count < judging_round.min_external_comment_words
        errors.add(:external_comments, "must be at least #{judging_round.min_external_comment_words} words")
      end
    end
  end
end
