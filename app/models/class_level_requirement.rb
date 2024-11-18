# == Schema Information
#
# Table name: class_level_requirements
#
#  id                  :bigint           not null, primary key
#  contest_instance_id :bigint           not null
#  class_level_id      :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class ClassLevelRequirement < ApplicationRecord
  belongs_to :contest_instance
  belongs_to :class_level
end
