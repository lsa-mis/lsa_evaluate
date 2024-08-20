# == Schema Information
#
# Table name: contest_instances
#
#  id                                   :bigint           not null, primary key
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
#  category_id                          :bigint           not null
#  contest_description_id               :bigint           not null
#  status_id                            :bigint           not null
#
# Indexes
#
#  category_id_idx                                    (category_id)
#  contest_description_id_idx                         (contest_description_id)
#  id_unq_idx                                         (id) UNIQUE
#  index_contest_instances_on_category_id             (category_id)
#  index_contest_instances_on_contest_description_id  (contest_description_id)
#  index_contest_instances_on_status_id               (status_id)
#  status_id_idx                                      (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_description_id => contest_descriptions.id)
#  fk_rails_...  (status_id => statuses.id)
#
FactoryBot.define do
  factory :contest_instance do
    status
    contest_description
    category
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
  end
end
