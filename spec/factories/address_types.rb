# == Schema Information
#
# Table name: address_types
#
#  id          :bigint           not null, primary key
#  kind        :string(255)      not null
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :address_type do
    # kind { 'Home' }
    sequence(:kind) { |n| "Kind #{n}" } # Use a unique sequence for kind
    description { Faker::Lorem.sentence }

    trait :home do
      kind { 'Home' }
    end

    trait :campus do
      kind { 'Campus' }
    end

    factory :home_address_type, traits: [ :home ]
    factory :campus_address_type, traits: [ :campus ]
  end
end
