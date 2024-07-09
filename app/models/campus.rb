class Campus < ApplicationRecord
  validates :campus_descr, presence: true, uniqueness: true
  validates :campus_cd, presence: true, uniqueness: true
end
