# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#  role_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_assignments_on_container_id              (container_id)
#  index_assignments_on_role_id                   (role_id)
#  index_assignments_on_role_user_container       (role_id,user_id,container_id) UNIQUE
#  index_assignments_on_user_id                   (user_id)
#  index_assignments_on_user_id_and_container_id  (user_id,container_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
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
