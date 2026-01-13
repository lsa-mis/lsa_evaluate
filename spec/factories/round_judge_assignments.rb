# == Schema Information
#
# Table name: round_judge_assignments
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  instructions_sent_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  judging_round_id     :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_round_judge_assignments_on_judging_round_id              (judging_round_id)
#  index_round_judge_assignments_on_judging_round_id_and_user_id  (judging_round_id,user_id) UNIQUE
#  index_round_judge_assignments_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (judging_round_id => judging_rounds.id)
#  fk_rails_...  (user_id => users.id)
#
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
