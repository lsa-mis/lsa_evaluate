# == Schema Information
#
# Table name: judging_rounds
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(FALSE), not null
#  completed           :boolean          default(FALSE), not null
#  end_date            :datetime
#  round_number        :integer          not null
#  start_date          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contest_instance_id :bigint           not null
#
# Indexes
#
#  index_judging_rounds_on_contest_instance_id                   (contest_instance_id)
#  index_judging_rounds_on_contest_instance_id_and_round_number  (contest_instance_id,round_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#
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
