# == Schema Information
#
# Table name: campuses
#
#  id           :bigint           not null, primary key
#  campus_descr :string(255)      not null
#  campus_cd    :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Campus < ApplicationRecord
  self.table_name = 'campuses'

  validates :campus_descr, presence: true, uniqueness: true
  validates :campus_cd, presence: true, uniqueness: true
end
