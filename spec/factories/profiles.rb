FactoryBot.define do
  factory :profile do
    user
    legal_first_name { Faker::Name.first_name }
    legal_last_name { Faker::Name.last_name }
    preferred_first_name { Faker::Name.first_name }
    preferred_last_name { Faker::Name.last_name }
    umid { format('%08d', Faker::Number.number(digits: 8)) }
    class_level
    school
    campus
    major { Faker::Educator.subject }
    department { Faker::Educator.subject }
    grad_date { Faker::Date.forward(days: 365) }
    degree { Faker::Educator.degree }
    receiving_financial_aid { false }
    accepted_financial_aid_notice { false }
    campus_employee { false }
    financial_aid_description { nil }
    hometown_publication { Faker::Address.city }
    pen_name { Faker::Book.author }
  end
end
