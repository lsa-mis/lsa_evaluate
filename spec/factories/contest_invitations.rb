# frozen_string_literal: true

FactoryBot.define do
  factory :contest_invitation do
    contest_instance
    sequence(:email) { |n| "invitee#{n}@umich.edu" }
    association :invited_by, factory: :user
  end
end
