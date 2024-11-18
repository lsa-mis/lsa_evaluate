# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  container_id :bigint           not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_by   :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#

FactoryBot.define do
  factory :contest_description do
    container
    sequence(:name) { |n| Faker::Lorem.word + " #{n}" }
    short_name { Faker::Lorem.unique.word }
    created_by { Faker::Name.name }

    transient do
      eligibility_rules_body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
      notes_body { Faker::Lorem.paragraph }
    end

    after(:build) do |contest_description, evaluator|
      contest_description.eligibility_rules = ActionText::RichText.new(body: evaluator.eligibility_rules_body)
      contest_description.notes = ActionText::RichText.new(body: evaluator.notes_body)
    end

    trait :active do
      active { true }
    end

    trait :archived do
      archived { true }
    end
  end
end
