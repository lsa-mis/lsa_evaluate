# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  container_id :bigint           not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_by   :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#
class ContestDescription < ApplicationRecord
  belongs_to :container
  has_many :contest_instances, dependent: :restrict_with_error

  has_rich_text :eligibility_rules
  has_rich_text :notes

  # accepts_nested_attributes_for :contest_instances, allow_destroy: true

  validates :created_by, presence: true
  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :archived, -> { where(archived: true) }
end
