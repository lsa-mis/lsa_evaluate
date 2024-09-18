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
  has_many :contest_instances, dependent: :destroy

  has_rich_text :eligibility_rules
  has_rich_text :notes

  accepts_nested_attributes_for :contest_instances, allow_destroy: true

  validates :name, :created_by, presence: true

  scope :active, -> { where(active: true) }
  scope :archived, -> { where(archived: true) }
end
