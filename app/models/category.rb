# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  description  :text(65535)
#  kind         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_categories_on_container_id           (container_id)
#  index_categories_on_container_id_and_kind  (container_id,kind) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
class Category < ApplicationRecord
  belongs_to :container
  has_many :category_contest_instances, dependent: :restrict_with_error
  has_many :contest_instances, through: :category_contest_instances
  has_many :entries, dependent: :restrict_with_error

  validates :kind, presence: true,
                   uniqueness: { scope: :container_id, case_sensitive: false }
  validates :description, presence: true

  scope :ordered, -> { order(:kind, :id) }
end
