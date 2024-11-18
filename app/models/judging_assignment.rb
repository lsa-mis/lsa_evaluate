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
