# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#  created_by   :string(255)      not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
class ContestDescription < ApplicationRecord
  belongs_to :container
  has_many :contest_instances, dependent: :restrict_with_error

  has_rich_text :eligibility_rules
  has_rich_text :notes

  validates :created_by, presence: true
  validates :name, presence: true, uniqueness: true
  validate :cannot_deactivate_with_active_instances

  scope :active, -> { where(active: true) }

  def active_contest_instances
    contest_instances.where(active: true)
  end

  private

  def cannot_deactivate_with_active_instances
    if will_save_change_to_active? && !active && contest_instances.where(active: true).exists?
      errors.add(:active, 'Cannot deactivate contest description while instances are active.')
    end
  end
end
