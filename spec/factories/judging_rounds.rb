# == Schema Information
#
# Table name: judging_rounds
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(FALSE), not null
#  completed                  :boolean          default(FALSE), not null
#  end_date                   :datetime
#  min_external_comment_words :integer          default(0), not null
#  min_internal_comment_words :integer          default(0), not null
#  require_external_comments  :boolean          default(FALSE), not null
#  require_internal_comments  :boolean          default(FALSE), not null
#  round_number               :integer          not null
#  special_instructions       :text(65535)
#  start_date                 :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  contest_instance_id        :bigint           not null
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
    active { false }
    completed { false }
    start_date { contest_instance.date_closed + 1.day }
    end_date { start_date + 1.day }
    require_internal_comments { false }
    require_external_comments { false }
    min_internal_comment_words { 0 }
    min_external_comment_words { 0 }
    special_instructions { nil }

    trait :completed do
      completed { true }
    end

    trait :inactive do
      active { false }
    end

    trait :with_comment_requirements do
      require_internal_comments { true }
      require_external_comments { true }
      min_internal_comment_words { 5 }
      min_external_comment_words { 10 }
    end

    trait :with_round_judge_assignments do
      transient do
        judges_count { 2 }
      end

      after(:create) do |round, evaluator|
        create_list(:round_judge_assignment, evaluator.judges_count, judging_round: round)
      end
    end

    trait :with_special_instructions do
      special_instructions { "Instructions for round #{round_number}" }
    end
  end
end
