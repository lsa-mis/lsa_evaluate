# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  name          :string(255)
#  notes         :text(65535)
#  department_id :bigint           not null
#  visibility_id :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :container do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    department
    visibility
  end
end
