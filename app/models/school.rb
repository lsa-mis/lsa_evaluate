# == Schema Information
#
# Table name: schools
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  id_unq_idx  (id) UNIQUE
#
class School < ApplicationRecord
  RACKHAM_NAME = 'Rackham'

  validates :name, presence: true
  validates :id, uniqueness: true

  def self.rackham
    find_by(name: RACKHAM_NAME)
  end
end
