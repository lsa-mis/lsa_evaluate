# == Schema Information
#
# Table name: judging_rounds
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(FALSE), not null
#  completed                  :boolean          default(FALSE), not null
#  emails_sent_count          :integer          default(0), not null
#  end_date                   :datetime
#  min_external_comment_words :integer          default(0), not null
#  min_internal_comment_words :integer          default(0), not null
#  require_external_comments  :boolean          default(FALSE), not null
#  require_internal_comments  :boolean          default(FALSE), not null
#  required_entries_count     :integer          default(0), not null
#  round_number               :integer          not null
#  special_instructions       :text(65535)
#  start_date                 :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  contest_instance_id        :bigint           not null
#
# Indexes
#
#  index_judging_rounds_on_contest_instance_id                   (contest_instance_id)
#  index_judging_rounds_on_contest_instance_id_and_round_number  (contest_instance_id,round_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#
class JudgingRound < ApplicationRecord
  belongs_to :contest_instance
  has_many :entry_rankings, dependent: :destroy
  has_many :entries, through: :entry_rankings
  has_many :round_judge_assignments, dependent: :destroy
  has_many :judges, through: :round_judge_assignments, source: :user

  validates :round_number, presence: true,
            numericality: { greater_than: 0 }
  validates :round_number, uniqueness: { scope: :contest_instance_id }
  validates :start_date, :end_date, presence: true
  validates :required_entries_count, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :dates_are_valid
  validate :start_date_after_previous_round
  validate :only_one_active_round_per_contest

  scope :active, -> { where(active: true) }

  before_create :set_active_by_default

  # Alias for completed? to match what's used in views
  def complete?
    completed?
  end

  def activate!
    return false unless valid?

    self.active = true  # Set this first so validation picks up the change
    return false unless validate_previous_rounds_completed

    JudgingRound.transaction do
      contest_instance.judging_rounds.active.update_all(active: false)
      save!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    if e.record.errors.include?(:active)
      errors.add(:base, 'There is already an active judging round for this contest')
    end
    false
  end

  def deactivate!
    update!(active: false)
  end

  def complete!
    return false unless valid?
    return false unless validate_previous_rounds_completed
    update!(completed: true, active: false)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def uncomplete!
    return false unless valid?
    update!(completed: false)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def assign_judge(user)
    return false unless user.judge?
    round_judge_assignments.create(user: user)
  end

  def validate_previous_rounds_completed
    return true if round_number == 1

    previous_rounds = contest_instance.judging_rounds
                     .where('round_number < ?', round_number)

    if previous_rounds.exists?(completed: false)
      error_message = active_changed? && active ?
        'All previous rounds must be completed before activating this round' :
        'All previous rounds must be completed before completing this round'
      errors.add(:base, error_message)
      return false
    end

    true
  end

  def average_rank_for_entry(entry)
    entry_rankings.where(entry: entry).where.not(rank: nil).average(:rank)&.round(2)
  end

  private

  def dates_are_valid
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end

    # First round must start after contest closes
    if round_number == 1 && start_date && contest_instance&.date_closed
      if start_date < contest_instance.date_closed
        errors.add(:start_date, "must be after contest close date (#{I18n.l(contest_instance.date_closed, format: :long)})")
      end
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

  def only_one_active_round_per_contest
    if active && contest_instance.judging_rounds.where(active: true).where.not(id: id).exists?
      errors.add(:base, 'There can only be one active judging round per contest instance')
    end
  end

  def set_active_by_default
    self.active = contest_instance.judging_rounds.count.zero?
  end
end
