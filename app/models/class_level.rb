# == Schema Information
#
# Table name: class_levels
#
#  id          :bigint           not null, primary key
#  description :text(65535)      not null
#  name        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ClassLevel < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
end
