FactoryBot.define do
  factory :judging_assignment do
    user
    contest_instance
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_non_judge_user do
      user { create(:user, :student) }
    end
  end
end
