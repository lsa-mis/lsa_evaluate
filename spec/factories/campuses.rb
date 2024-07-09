FactoryBot.define do
  factory :campus do
    campus_descr { Faker::Address.community }
    campus_cd { Faker::Number.unique.number(digits: 4) }
  end
end
