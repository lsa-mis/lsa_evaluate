# == Schema Information
#
# Table name: judging_assignments
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint           not null
#  contest_instance_id :bigint           not null
#  active              :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# app/models/judging_assignment.rb
class JudgingAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :contest_instance

  validates :user_id, uniqueness: { scope: :contest_instance_id }
  validate :user_must_be_judge

  private

  def user_must_be_judge
    unless user&.judge?
      errors.add(:user, 'must have judge role')
    end
  end
end
