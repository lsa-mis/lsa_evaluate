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
class ContestInstance < ApplicationRecord
  has_many :class_level_requirements, dependent: :destroy
  has_many :class_levels, through: :class_level_requirements
  has_many :category_contest_instances, dependent: :destroy
  has_many :categories, through: :category_contest_instances
  has_many :entries, dependent: :destroy
  belongs_to :contest_description

  scope :active_and_open, -> {
    where(active: true)
    .where(archived: false)
    .where('date_open <= ? AND date_closed >= ?', Time.zone.now, Time.zone.now)
  }

  scope :active_and_open_for_container, ->(container_id) {
    active_and_open
    .joins(contest_description: :container)
    .where(contest_descriptions: { container_id: container_id })
  }

  accepts_nested_attributes_for :category_contest_instances, allow_destroy: true
  accepts_nested_attributes_for :class_level_requirements, allow_destroy: true

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
  validate :must_have_at_least_one_class_level_requirement
  validate :must_have_at_least_one_category
  validate :only_one_active_per_contest_description
  validate :date_closed_after_date_open

  def dup_with_associations
    new_instance = dup
    new_instance.active = false
    new_instance.created_by = nil
    new_instance.date_closed = nil
    new_instance.date_open = nil
    new_instance.judging_open = false
    new_instance.archived = false

    class_level_requirements.each do |clr|
      new_instance.class_level_requirements.build(clr.attributes.except('id', 'contest_instance_id', 'created_at', 'updated_at'))
    end

    category_contest_instances.each do |cci|
      new_instance.category_contest_instances.build(cci.attributes.except('id', 'contest_instance_id', 'created_at', 'updated_at'))
    end

    new_instance
  end

  def display_name
    "#{contest_description.name} - #{date_open.strftime('%Y-%m-%d')} to #{date_closed.strftime('%Y-%m-%d')}"
  end

  def is_open?
    active && !archived && DateTime.now.between?(date_open, date_closed)
  end

  def must_have_at_least_one_class_level_requirement
    if class_level_requirements.empty?
      errors.add(:base, 'At least one class level requirement must be added.')
    end
  end

  def must_have_at_least_one_category
    if category_contest_instances.empty?
      errors.add(:base, 'At least one category must be added.')
    end
  end

  def only_one_active_per_contest_description
    if active && contest_description.contest_instances.where(active: true).where.not(id: id).exists?
      errors.add(:active, 'There can only be one active contest instance for a contest description.')
    end
  end

  def date_closed_after_date_open
    if date_open && date_closed && date_closed < date_open
      errors.add(:date_closed, 'must be after date contest opens')
    end
  end
end
