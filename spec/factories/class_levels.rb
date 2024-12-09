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
FactoryBot.define do
  factory :class_level do
    sequence(:name) { |n| "Class Level #{n}" }
    sequence(:description) { |n| "Description for Class Level #{n}" }
  end
end
