# frozen_string_literal: true

FactoryBot.define do
  factory :entry_award do
    entry
    award { association(:award, container: entry.contest_instance.contest_description.container) }

    trait :add_on do
      award { association(:award, :add_on, container: entry.contest_instance.contest_description.container) }
    end
  end
end
