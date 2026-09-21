# frozen_string_literal: true

FactoryBot.define do
  factory :award do
    container
    sequence(:name) { |n| "Award #{n}" }
    kind { 'primary' }
    default_amount { 1000.00 }
    default_shortcode { 'P/G123456' }
    description { 'Prize from the collection catalog' }
    active { true }

    trait :add_on do
      kind { 'add_on' }
      sequence(:name) { |n| "Add-on prize #{n}" }
      default_amount { 250.00 }
      default_shortcode { 'P/G654321' }
    end

    trait :inactive do
      active { false }
    end
  end
end
