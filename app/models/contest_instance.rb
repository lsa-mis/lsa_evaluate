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
#  contest_description_id               :bigint           not null
#  status_id                            :bigint           not null
#
# Indexes
#
#  contest_description_id_idx                         (contest_description_id)
#  id_unq_idx                                         (id) UNIQUE
#  index_contest_instances_on_contest_description_id  (contest_description_id)
#  index_contest_instances_on_status_id               (status_id)
#  status_id_idx                                      (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (contest_description_id => contest_descriptions.id)
#  fk_rails_...  (status_id => statuses.id)
#
class ContestInstance < ApplicationRecord
  has_many :class_level_requirements, dependent: :destroy
  has_many :class_levels, through: :class_level_requirements
  has_many :category_contest_instances, dependent: :destroy
  has_many :categories, through: :category_contest_instances
  has_many :entries

  belongs_to :status
  belongs_to :contest_description

  accepts_nested_attributes_for :category_contest_instances, allow_destroy: true

  validates :date_open, presence: true
  validates :date_closed, presence: true
  validates :judging_open, inclusion: { in: [ true, false ] }
  validates :judging_rounds, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :has_course_requirement, inclusion: { in: [ true, false ] }
  validates :judge_evaluations_complete, inclusion: { in: [ true, false ] }
  validates :recletter_required, inclusion: { in: [ true, false ] }
  validates :transcript_required, inclusion: { in: [ true, false ] }
  validates :maximum_number_entries_per_applicant, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :created_by, presence: true

  def display_name
    "#{contest_description.name} - #{date_open.strftime('%Y-%m-%d')} to #{date_closed.strftime('%Y-%m-%d')}"
  end

  def is_open?
    status.kind.downcase == 'active' && DateTime.now.between?(date_open, date_closed)
  end
end
