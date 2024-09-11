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
#  judging_rounds                       :integer          default(1)
#  maximum_number_entries_per_applicant :integer          default(1), not null
#  notes                                :text(65535)
#  recletter_required                   :boolean          default(FALSE), not null
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
    date_open { Faker::Date.backward(days: 14) }
    date_closed { Faker::Date.forward(days: 14) }
    notes { Faker::Lorem.paragraph }
    judging_open { false }
    judging_rounds { 1 }
    has_course_requirement { false }
    judge_evaluations_complete { false }
    course_requirement_description { Faker::Lorem.paragraph }
    recletter_required { false }
    transcript_required { false }
    maximum_number_entries_per_applicant { 1 }
    created_by { Faker::Name.name }

    # after(:create) do |contest_instance|
    #   create_list(:category_contest_instance, 1, contest_instance: contest_instance)
    #   create(:class_level_requirement, contest_instance: contest_instance)
    # end
    after(:build) do |contest_instance|
      contest_instance.class_level_requirements << build(:class_level_requirement, contest_instance: contest_instance)
      contest_instance.category_contest_instances << build(:category_contest_instance, contest_instance: contest_instance, category: create(:category))
    end
  end
end
