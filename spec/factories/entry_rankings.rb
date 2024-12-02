FactoryBot.define do
  factory :entry_ranking do
    entry
    judging_round
    user { create(:user, :with_judge_role) }
    rank { rand(1..10) }
    notes { Faker::Lorem.paragraph }
    selected_for_next_round { false }

    trait :selected do
      selected_for_next_round { true }
    end

    trait :with_assigned_judge do
      after(:build) do |entry_ranking|
        create(:judging_assignment, 
          user: entry_ranking.user, 
          contest_instance: entry_ranking.judging_round.contest_instance, 
          active: true
        )
        create(:round_judge_assignment,
          user: entry_ranking.user,
          judging_round: entry_ranking.judging_round,
          active: true
        )
      end
    end
  end
end 