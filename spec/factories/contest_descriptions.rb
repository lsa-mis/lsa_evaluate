# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#  created_by   :string(255)      not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#

FactoryBot.define do
  factory :contest_description do
    sequence(:name) { |n| "Contest Description #{n}" }
    sequence(:short_name) { |n| "Contest#{n}" }
    sequence(:created_by) { |n| "Creator #{n}" }
    container
    active { false }

    transient do
      eligibility_rules_body { "Eligibility rules for #{name}" }
      notes_body { "Notes for #{name}" }
    end

    after(:build) do |contest_description, evaluator|
      contest_description.eligibility_rules = ActionText::RichText.new(body: evaluator.eligibility_rules_body)
      contest_description.notes = ActionText::RichText.new(body: evaluator.notes_body)
    end

    trait :active do
      active { true }
    end

    trait :with_instance do
      after(:create) do |contest_description|
        create(:contest_instance, contest_description: contest_description)
      end
    end
  end
end
