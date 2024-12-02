FactoryBot.define do
  factory :round_judge_assignment do
    judging_round
    user { create(:user, :with_judge_role) }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_contest_assignment do
      after(:build) do |assignment|
        create(:judging_assignment,
          user: assignment.user,
          contest_instance: assignment.judging_round.contest_instance,
          active: true
        )
      end
    end
  end
end 