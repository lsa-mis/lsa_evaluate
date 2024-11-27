FactoryBot.define do
  factory :judging_assignment do
    user { create(:user, :with_judge_role) }
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
