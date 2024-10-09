# == Schema Information
#
# Table name: visibilities
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'factory_bot_rails'

FactoryBot.define do
  factory :visibility do
    kind { 'Public' }
    description { Faker::Lorem.sentence(word_count: 5) }

    trait :public do
      kind { 'Public' }
    end

    trait :private do
      kind { 'Private' }
    end
  end
end
