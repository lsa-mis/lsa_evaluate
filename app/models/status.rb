# == Schema Information
#
# Table name: statuses
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_statuses_on_kind  (kind) UNIQUE
#
class Status < ApplicationRecord
  has_many :contest_descriptions
  has_many :contest_instances
  validates :kind, presence: true, inclusion: { in: %w[Active Deleted Archived Disqualified] }, uniqueness: true
  validates :description, presence: true
end
