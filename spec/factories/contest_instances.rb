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
    association :contest_description, :active  # Associate with an active contest description
    date_open { 1.day.ago }
    date_closed { 1.day.from_now }
    active { true }
    notes { "Notes for contest instance" }
    has_course_requirement { false }
    course_requirement_description { "Course requirements" }
    recletter_required { false }
    transcript_required { false }
    maximum_number_entries_per_applicant { 1 }
    require_pen_name { false }
    sequence(:created_by) { |n| "Creator #{n}" }
    require_finaid_info { false }
    require_campus_employment_info { false }

    # Ensure class levels and categories are added before validation
    after(:build) do |contest_instance|
      if contest_instance.class_levels.empty?
        contest_instance.class_levels << build(:class_level)
      end

      if contest_instance.categories.empty?
        contest_instance.categories << build(:category)
      end
    end

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

    trait :inactive do
      active { false }
    end

    # For testing validation failures
    trait :without_class_levels do
      after(:build) do |contest_instance|
        contest_instance.class_levels = []
      end
    end

    trait :without_categories do
      after(:build) do |contest_instance|
        contest_instance.categories = []
      end
    end
  end
end
