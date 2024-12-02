# == Schema Information
#
# Table name: contest_instances
#
#  id                                   :bigint           not null, primary key
#  active                               :boolean          default(FALSE), not null
#  archived                             :boolean          default(FALSE), not null
#  course_requirement_description       :text(65535)
#  created_by                           :string(255)
#  date_closed                          :datetime         not null
#  date_open                            :datetime         not null
#  has_course_requirement               :boolean          default(FALSE), not null
#  judge_evaluations_complete           :boolean          default(FALSE), not null
#  judging_open                         :boolean          default(FALSE), not null
#  maximum_number_entries_per_applicant :integer          default(1), not null
#  notes                                :text(65535)
#  recletter_required                   :boolean          default(FALSE), not null
#  require_campus_employment_info       :boolean          default(FALSE), not null
#  require_finaid_info                  :boolean          default(FALSE), not null
#  require_pen_name                     :boolean          default(FALSE), not null
#  transcript_required                  :boolean          default(FALSE), not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  contest_description_id               :bigint           not null
#
# Indexes
#
#  contest_description_id_idx                         (contest_description_id)
#  id_unq_idx                                         (id) UNIQUE
#  index_contest_instances_on_contest_description_id  (contest_description_id)
#
# Foreign Keys
#
#  fk_rails_...  (contest_description_id => contest_descriptions.id)
#

FactoryBot.define do
  factory :contest_instance do
    active { true }
    archived { false }
    contest_description
    date_open { 1.day.ago }
    date_closed { 1.day.from_now }
    notes { Faker::Lorem.paragraph }
    judging_open { false }
    has_course_requirement { false }
    judge_evaluations_complete { false }
    course_requirement_description { Faker::Lorem.paragraph }
    recletter_required { false }
    transcript_required { false }
    maximum_number_entries_per_applicant { 1 }
    require_pen_name { false }
    created_by { Faker::Name.name }
    require_finaid_info { false }
    require_campus_employment_info { false }

    # Allow overriding date_closed in tests
    trait :closed do
      date_closed { 1.day.ago }
    end

    trait :open do
      date_closed { 1.day.from_now }
    end

    trait :with_judging_round do
      after(:create) do |contest_instance|
        create(:judging_round, contest_instance: contest_instance)
      end
    end
    # Transient attributes for flexibility
    transient do
      class_levels_count { 1 }
      categories_count { 1 }
      class_levels { [] }
      categories { [] }
    end

    after(:build) do |contest_instance, evaluator|
      # Associate class_levels
      if evaluator.class_levels.any?
        contest_instance.class_levels = evaluator.class_levels
      else
        evaluator.class_levels_count.times do
          contest_instance.class_levels << build(:class_level)
        end
      end

      # Associate categories
      if evaluator.categories.any?
        contest_instance.categories = evaluator.categories
      else
        evaluator.categories_count.times do
          contest_instance.categories << build(:category)
        end
      end
    end
  end
end
