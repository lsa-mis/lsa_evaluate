# == Schema Information
#
# Table name: roles
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :role do
    kind { Faker::Job.title }
    description { Faker::Lorem.paragraph }
  end
end
