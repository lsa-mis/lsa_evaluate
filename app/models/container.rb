# frozen_string_literal: true

# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  description   :text(65535)
#  name          :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  department_id :bigint           not null
#  visibility_id :bigint           not null
#
# Indexes
#
#  index_containers_on_department_id  (department_id)
#  index_containers_on_visibility_id  (visibility_id)
#
# Foreign Keys
#
#  fk_rails_...  (department_id => departments.id)
#  fk_rails_...  (visibility_id => visibilities.id)
#
class Container < ApplicationRecord
  belongs_to :department
  belongs_to :visibility
  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :roles, through: :assignments
  has_many :contest_descriptions, dependent: :destroy

  attr_accessor :creator

  accepts_nested_attributes_for :assignments, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contest_descriptions, allow_destroy: true

  after_create :assign_container_administrator

  private

  def assign_container_administrator
    return if creator.blank?  # Skip if creator is nil
    container_admin_role = Role.find_by(kind: 'Container Administrator')

    if container_admin_role.present?
      assignment = assignments.create(user: creator, role: container_admin_role)
      unless assignment.persisted?
        raise ActiveRecord::Rollback, 'Container Administrator assignment failed to be created'
      end
    else
      errors.add(:base, 'Container Administrator role not found.')
      raise ActiveRecord::Rollback
    end
  end
end
