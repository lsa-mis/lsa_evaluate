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
FactoryBot.define do
  factory :class_level_requirement do
    contest_instance
    class_level
  end
end
