# == Schema Information
#
# Table name: judging_assignments
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contest_instance_id :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_judging_assignments_on_contest_instance_id              (contest_instance_id)
#  index_judging_assignments_on_user_id                          (user_id)
#  index_judging_assignments_on_user_id_and_contest_instance_id  (user_id,contest_instance_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :judging_assignment do
    contest_instance
    association :user, :with_judge_role
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_non_judge_user do
      association :user, :student
    end
  end
end
