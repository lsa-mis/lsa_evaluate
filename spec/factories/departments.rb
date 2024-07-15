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
FactoryBot.define do
  factory :department do
    dept_id { Faker::Number.number(digits: 6) }
    name { Faker::Company.department }
    dept_description { Faker::Company.bs }
  end
end
