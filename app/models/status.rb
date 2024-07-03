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
class Status < ApplicationRecord
  validates :kind, presence: true, uniqueness: true, inclusion: { in: %w[Active Deleted Archived Disqualified] }
  validates :description, presence: true
end
