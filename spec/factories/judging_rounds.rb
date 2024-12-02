FactoryBot.define do
  factory :judging_round do
    contest_instance
    sequence(:round_number) { |n| n }
    active { true }
    completed { false }
    
    trait :completed do
      completed { true }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :with_round_judge_assignments do
      transient do
        judges_count { 2 }
      end
      
      after(:create) do |round, evaluator|
        create_list(:round_judge_assignment, evaluator.judges_count, judging_round: round)
      end
    end
  end
end 