# == Schema Information
#
# Table name: departments
#
#  id               :bigint           not null, primary key
#  dept_description :text(65535)
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dept_id          :integer          not null
#
class Department < ApplicationRecord
  has_many :containers, dependent: :destroy

  validates :name, presence: true
  validates :dept_id, presence: true
end
