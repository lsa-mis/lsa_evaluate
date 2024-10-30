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
# spec/models/contest_instance_spec.rb

require 'rails_helper'

RSpec.describe ContestInstance, type: :model do
  describe 'associations' do
    it 'belongs to contest_description' do
      association = described_class.reflect_on_association(:contest_description)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many categories through category_contest_instances' do
      association = described_class.reflect_on_association(:categories)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:category_contest_instances)
    end

    it 'has many category_contest_instances' do
      association = described_class.reflect_on_association(:category_contest_instances)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many class_levels through class_level_requirements' do
      association = described_class.reflect_on_association(:class_levels)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:class_level_requirements)
    end

    it 'has many class_level_requirements' do
      association = described_class.reflect_on_association(:class_level_requirements)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    let(:contest_instance) { build(:contest_instance) }

    it 'is valid with valid attributes' do
      expect(contest_instance).to be_valid
    end

    it 'is invalid without a date_open' do
      contest_instance.date_open = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:date_open]).to include("can't be blank")
    end

    it 'is invalid without a date_closed' do
      contest_instance.date_closed = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:date_closed]).to include("can't be blank")
    end

    it 'is invalid without a judging_rounds' do
      contest_instance.judging_rounds = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:judging_rounds]).to include("can't be blank")
    end

    it 'is invalid with non-integer judging_rounds' do
      contest_instance.judging_rounds = 'one'
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:judging_rounds]).to include('is not a number')
    end

    it 'is invalid with judging_rounds less than 1' do
      contest_instance.judging_rounds = 0
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:judging_rounds]).to include('must be greater than 0')
    end

    it 'is invalid without a maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include("can't be blank")
    end

    it 'is invalid with non-integer maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = 'one'
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include('is not a number')
    end

    it 'is invalid with maximum_number_entries_per_applicant less than 1' do
      contest_instance.maximum_number_entries_per_applicant = 0
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include('must be greater than 0')
    end

    it 'is invalid without a created_by' do
      contest_instance.created_by = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:created_by]).to include("can't be blank")
    end

    it 'is invalid without judging_open being true or false' do
      contest_instance.judging_open = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:judging_open]).to include('is not included in the list')
    end

    it 'is invalid without has_course_requirement being true or false' do
      contest_instance.has_course_requirement = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:has_course_requirement]).to include('is not included in the list')
    end

    it 'is invalid without judge_evaluations_complete being true or false' do
      contest_instance.judge_evaluations_complete = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:judge_evaluations_complete]).to include('is not included in the list')
    end

    it 'is invalid without recletter_required being true or false' do
      contest_instance.recletter_required = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:recletter_required]).to include('is not included in the list')
    end

    it 'is invalid without transcript_required being true or false' do
      contest_instance.transcript_required = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:transcript_required]).to include('is not included in the list')
    end

    it 'is invalid without at least one class_level selected' do
      contest_instance.class_levels.clear
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:base]).to include('At least one class level requirement must be selected.')
    end

    it 'is invalid without at least one category selected' do
      contest_instance.categories.clear
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:base]).to include('At least one category must be selected.')
    end

    it 'is invalid with more than one active contest instance for a contest description' do
      contest_description = create(:contest_description)
      create(:contest_instance, contest_description: contest_description, active: true)
      contest_instance = build(:contest_instance, contest_description: contest_description, active: true)
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:active]).to include('There can only be one active contest instance for a contest description.')
    end

    it 'is invalid if date_open is after date_closed' do
      contest_instance.date_open = 2.days.from_now
      contest_instance.date_closed = 2.days.ago
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:date_closed]).to include('must be after date contest opens')
    end

    it 'is invalid without a maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = nil
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include("can't be blank")
    end

    it 'is invalid with non-integer maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = 'one'
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include('is not a number')
    end

    it 'is invalid with maximum_number_entries_per_applicant less than 1' do
      contest_instance.maximum_number_entries_per_applicant = 0
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:maximum_number_entries_per_applicant]).to include('must be greater than 0')
    end
  end

  describe 'Factory' do
    it 'is valid with valid attributes' do
      contest_instance = build(:contest_instance)
      expect(contest_instance).to be_valid
    end
  end

  describe '#open?' do
    context 'when the current date is between date_open and date_closed and is active' do
      it 'returns true' do
        contest_instance = create(:contest_instance, date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.open?).to be(true)
      end
    end

    context 'when the current date is between date_open and date_closed but is not active' do
      it 'returns false' do
        contest_instance = create(:contest_instance, active: false, date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.open?).to be(false)
      end
    end

    context 'when the current date is before date_open' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 2.days.from_now, date_closed: 4.days.from_now)
        expect(contest_instance.open?).to be(false)
      end
    end

    context 'when the current date is after date_closed' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 4.days.ago, date_closed: 2.days.ago)
        expect(contest_instance.open?).to be(false)
      end
    end

    context 'when it is archived' do
      it 'returns false' do
        contest_instance = create(:contest_instance, archived: true)
        expect(contest_instance.open?).to be(false)
      end
    end
  end

  describe '.active_and_open' do
    let!(:active_open_contest) { create(:contest_instance, date_open: 1.day.ago, date_closed: 1.day.from_now) }
    let!(:active_closed_contest) { create(:contest_instance, date_open: 3.days.ago, date_closed: 1.day.ago) }
    let!(:archived_contest) { create(:contest_instance, archived: true, date_open: 5.days.ago, date_closed: 2.days.ago) }

    it 'returns only active contests within the date range' do
      expect(ContestInstance.active_and_open).to include(active_open_contest)
      expect(ContestInstance.active_and_open).not_to include(active_closed_contest)
      expect(ContestInstance.active_and_open).not_to include(archived_contest)
    end
  end

  describe '.for_class_level' do
    let(:class_level1) { create(:class_level) }
    let(:class_level2) { create(:class_level) }

    let!(:contest_with_class_level1) do
      contest_instance = create(:contest_instance, class_levels: [ class_level1 ])
      contest_instance
    end

    let!(:contest_with_class_level2) do
      contest_instance = create(:contest_instance, class_levels: [ class_level2 ])
      contest_instance
    end

    let!(:contest_with_both_class_levels) do
      contest_instance = create(:contest_instance, class_levels: [ class_level1, class_level2 ])
      contest_instance
    end

    it 'returns contests matching the specified class level' do
      result = ContestInstance.for_class_level(class_level1.id)
      expect(result).to include(contest_with_class_level1, contest_with_both_class_levels)
      expect(result).not_to include(contest_with_class_level2)
    end

    it 'returns contests matching the specified class level (class_level2)' do
      result = ContestInstance.for_class_level(class_level2.id)
      expect(result).to include(contest_with_class_level2, contest_with_both_class_levels)
      expect(result).not_to include(contest_with_class_level1)
    end

    it 'does not return contests without the specified class level' do
      class_level3 = create(:class_level)
      result = ContestInstance.for_class_level(class_level3.id)
      expect(result).to be_empty
    end

    it 'returns unique contests when multiple class levels are associated' do
      result = ContestInstance.for_class_level(class_level1.id)
      expect(result.count).to eq(2)
    end
  end

  describe '#dup_with_associations' do
    let!(:contest_instance) { create(:contest_instance) }

    before do
      # Ensure associations are present
      contest_instance.class_levels << create(:class_level)
      contest_instance.categories << create(:category)
    end

    it 'creates a new instance with the same attributes except specified ones' do
      new_instance = contest_instance.dup_with_associations
      expect(new_instance).to be_a_new(ContestInstance)
      expect(new_instance.active).to be(false)
      expect(new_instance.created_by).to be_nil
      expect(new_instance.date_closed).to be_nil
      expect(new_instance.date_open).to be_nil
      expect(new_instance.judging_open).to be(false)
      expect(new_instance.archived).to be(false)
    end

    it 'duplicates class_levels associations' do
      new_instance = contest_instance.dup_with_associations
      expect(new_instance.class_levels).to match_array(contest_instance.class_levels)
    end

    it 'duplicates categories associations' do
      new_instance = contest_instance.dup_with_associations
      expect(new_instance.categories).to match_array(contest_instance.categories)
    end
  end

  describe '.available_for_profile' do
    let(:profile) { create(:profile) }
    let(:other_profile) { create(:profile, campus: profile.campus) }
    let(:contest_instance_with_limit) { create(:contest_instance, maximum_number_entries_per_applicant: 1) }
    let(:contest_instance_high_limit) { create(:contest_instance, maximum_number_entries_per_applicant: 1000) }
    let(:contest_instance_closed) { create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago) }

    context 'when the profile has not reached the maximum number of entries' do
      it 'includes the contest instance' do
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).to include(contest_instance_with_limit)
      end
    end

    context 'when the profile has reached the maximum number of entries' do
      before do
        create(:entry, profile: profile, contest_instance: contest_instance_with_limit)
      end

      it 'excludes the contest instance' do
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).not_to include(contest_instance_with_limit)
      end

      it 'includes the contest instance for other profiles' do
        available_contests = ContestInstance.available_for_profile(other_profile)
        expect(available_contests).to include(contest_instance_with_limit)
      end
    end

    context 'when the profile has soft-deleted entries' do
      before do
        create(:entry, profile: profile, contest_instance: contest_instance_with_limit, deleted: true)
      end

      it 'includes the contest instance' do
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).to include(contest_instance_with_limit)
      end
    end

    context 'when the contest instance has a high entry limit' do
      before do
        create_list(:entry, 5, profile: profile, contest_instance: contest_instance_high_limit)
      end

      it 'includes the contest instance as limit is not reached' do
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).to include(contest_instance_high_limit)
      end

      it 'excludes the contest instance when limit is reached' do
        create_list(:entry, 995, profile: profile, contest_instance: contest_instance_high_limit)
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).not_to include(contest_instance_high_limit)
      end
    end

    context 'when the contest instance is closed' do
      it 'includes the contest instance if active_and_open is not applied' do
        available_contests = ContestInstance.available_for_profile(profile)
        expect(available_contests).to include(contest_instance_closed)
      end
    end
  end
end
