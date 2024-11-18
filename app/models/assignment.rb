# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  container_id :bigint           not null
#  role_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Assignment < ApplicationRecord
  attr_accessor :uid
  belongs_to :user
  belongs_to :container
  belongs_to :role

  scope :container_administrators, -> { joins(:role).where(roles: { kind: 'Collection Administrator' }) }

  validates :user_id, presence: true
  validates :role_id,
            uniqueness: { scope: %i[user_id container_id],
                          message: 'combination with user and collection must be unique' }
  validates :user_id, uniqueness: { scope: :container_id, message: 'is already assigned to this container' }

  before_destroy :ensure_at_least_one_admin_remains, if: :is_container_administrator?

  private

  def is_container_administrator?
    role.kind == 'Collection Administrator'
  end

  def ensure_at_least_one_admin_remains
    if container.assignments.container_administrators.count <= 1
      errors.add(:base, 'Cannot delete the last Container Administrator.')
      throw :abort
    end
  end
end
