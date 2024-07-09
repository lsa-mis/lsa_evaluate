# == Schema Information
#
# Table name: campuses
#
#  id           :bigint           not null, primary key
#  campus_cd    :integer          not null
#  campus_descr :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  campus_cd_unq_idx     (campus_cd) UNIQUE
#  campus_descr_idx      (campus_descr)
#  campus_descr_unq_idx  (campus_descr) UNIQUE
#  id_unq_idx            (id) UNIQUE
#
class Campus < ApplicationRecord
  self.table_name = 'campuses'

  validates :campus_descr, presence: true, uniqueness: true
  validates :campus_cd, presence: true, uniqueness: true
end
