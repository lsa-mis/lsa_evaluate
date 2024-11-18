# frozen_string_literal: true

# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  name          :string(255)
#  notes         :text(65535)
#  department_id :bigint           not null
#  visibility_id :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Container < ApplicationRecord
  belongs_to :department
  belongs_to :visibility
  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :roles, through: :assignments
  has_many :contest_descriptions, dependent: :restrict_with_error

  has_rich_text :description

  attr_accessor :creator

  accepts_nested_attributes_for :assignments, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contest_descriptions, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates :department_id, presence: { message: 'You must select a department' }
  validates :visibility_id, presence: { message: 'You must select a visibility option' }

  scope :visible, -> { joins(:visibility).where(visibilities: { kind: 'Public' }) } # Only show containers with 'Public' visibility

  after_create :assign_container_administrator

  private

  def assign_container_administrator
    return if creator.blank?  # Skip if creator is nil
    container_admin_role = Role.find_by(kind: 'Collection Administrator')

    if container_admin_role.present?
      assignment = assignments.create(user: creator, role: container_admin_role)
      unless assignment.persisted?
        raise ActiveRecord::Rollback, 'Collection Administrator assignment failed to be created'
      end
    else
      errors.add(:base, 'Collection Administrator role not found.')
      raise ActiveRecord::Rollback
    end
  end
end
