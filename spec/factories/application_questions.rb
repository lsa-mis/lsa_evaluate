# frozen_string_literal: true

FactoryBot.define do
  factory :application_question do
    container
    sequence(:key) { |n| "custom_question_#{n}" }
    label { 'Custom question' }
    field_type { 'string' }
    position { 100 }
    active { true }
  end
end
