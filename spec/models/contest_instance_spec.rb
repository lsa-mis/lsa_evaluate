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
require 'rails_helper'

RSpec.describe ContestInstance do
  describe 'associations' do
    it 'belongs to status' do
      association = described_class.reflect_on_association(:status)
      expect(association.macro).to eq(:belongs_to)
    end

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

    it 'is invalid without at least one class_level_requirement' do
      contest_instance.class_level_requirements.clear
      expect(contest_instance).not_to be_valid
      expect(contest_instance.errors[:base]).to include('At least one class level requirement must be added.')
    end
  end

  describe 'Factory' do
    it 'is valid with valid attributes' do
      contest_instance = FactoryBot.build(:contest_instance)
      expect(contest_instance).to be_valid
    end
  end

  describe '#is_open?' do
    context 'when the current date is between date_open and date_closed and status is active' do
      it 'returns true' do
        contest_instance = create(:contest_instance, date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.is_open?).to be(true)
      end
    end

    context 'when the current date is between date_open and date_closed but status is not active' do
      it 'returns false' do
        contest_instance = create(:contest_instance, status: create(:status, :archived), date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.is_open?).to be(false)
      end
    end

    context 'when the current date is before date_open' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 2.days.from_now, date_closed: 4.days.from_now)
        expect(contest_instance.is_open?).to be(false)
      end
    end

    context 'when the current date is after date_closed' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 4.days.ago, date_closed: 2.days.ago)
        expect(contest_instance.is_open?).to be(false)
      end
    end
  end

  describe '.active_and_open' do
    let!(:active_open_contest) { create(:contest_instance, date_open: 1.day.ago, date_closed: 1.day.from_now) }
    let!(:active_closed_contest) { create(:contest_instance, date_open: 3.days.ago, date_closed: 1.day.ago) }
    let!(:archived_contest) { create(:contest_instance, status: create(:status_archived), date_open: 1.day.ago, date_closed: 1.day.from_now) }

    it 'returns only active contests within the date range' do
      expect(ContestInstance.active_and_open).to include(active_open_contest)
      expect(ContestInstance.active_and_open).not_to include(active_closed_contest)
      expect(ContestInstance.active_and_open).not_to include(archived_contest)
    end
  end
end
