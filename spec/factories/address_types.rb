FactoryBot.define do
  factory :address_type do
    kind { Faker::Address.unique.community }
    description { Faker::Lorem.sentence }
  end
end
