# == Schema Information
#
# Table name: judging_assignments
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contest_instance_id :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_judging_assignments_on_contest_instance_id              (contest_instance_id)
#  index_judging_assignments_on_user_id                          (user_id)
#  index_judging_assignments_on_user_id_and_contest_instance_id  (user_id,contest_instance_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (user_id => users.id)
#
class JudgingAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :contest_instance

  validates :user_id, uniqueness: { scope: :contest_instance_id }
  validate :user_must_be_judge

  scope :active, -> { where(active: true) }

  private

  def user_must_be_judge
    unless user&.judge?
      errors.add(:user, 'must have judge role')
    end
  end
end
