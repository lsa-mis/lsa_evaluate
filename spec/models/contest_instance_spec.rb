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
require 'rails_helper'

RSpec.describe ContestInstance, type: :model do
  # Factory validation
  describe 'Factory' do
    it 'is valid with valid attributes' do
      contest_instance = build(:contest_instance)
      expect(contest_instance).to be_valid
    end
  end

  # Associations
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

  # Validations
  describe 'validations' do
    let(:contest_instance) { build(:contest_instance) }

    it 'is valid with valid attributes' do
      expect(contest_instance).to be_valid
    end

    it 'is invalid without a date_open' do
      contest_instance.date_open = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without a date_closed' do
      contest_instance.date_closed = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without a maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid with maximum_number_entries_per_applicant less than 1' do
      contest_instance.maximum_number_entries_per_applicant = 0
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid with non-integer maximum_number_entries_per_applicant' do
      contest_instance.maximum_number_entries_per_applicant = 1.5
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without a created_by' do
      contest_instance.created_by = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without has_course_requirement being true or false' do
      contest_instance.has_course_requirement = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without recletter_required being true or false' do
      contest_instance.recletter_required = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without transcript_required being true or false' do
      contest_instance.transcript_required = nil
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without must_have_at_least_one_class_level_requirement' do
      contest_instance.class_levels = []
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid without at least one category selected' do
      contest_instance.categories = []
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid with more than one active contest instance for a contest description' do
      contest_description = create(:contest_description)
      create(:contest_instance, contest_description: contest_description, active: true)
      contest_instance = build(:contest_instance, contest_description: contest_description, active: true)
      expect(contest_instance).not_to be_valid
    end

    it 'is invalid if date_open is after date_closed' do
      contest_instance.date_open = Time.current
      contest_instance.date_closed = 1.day.ago
      expect(contest_instance).not_to be_valid
    end
  end

  # Instance Methods
  describe '#open?' do
    context 'when the current date is between date_open and date_closed and is active' do
      it 'returns true' do
        contest_instance = create(:contest_instance, date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.open?).to be true
      end
    end

    context 'when the current date is between date_open and date_closed but is not active' do
      it 'returns false' do
        contest_instance = create(:contest_instance, active: false, date_open: 2.days.ago, date_closed: 2.days.from_now)
        expect(contest_instance.open?).to be false
      end
    end

    context 'when the current date is before date_open' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 2.days.from_now, date_closed: 4.days.from_now)
        expect(contest_instance.open?).to be false
      end
    end

    context 'when the current date is after date_closed' do
      it 'returns false' do
        contest_instance = create(:contest_instance, date_open: 4.days.ago, date_closed: 2.days.ago)
        expect(contest_instance.open?).to be false
      end
    end

    context 'when it is archived' do
      it 'returns false' do
        contest_instance = create(:contest_instance, archived: true)
        expect(contest_instance.open?).to be false
      end
    end
  end

  # Judge Assignment Methods
  describe 'judge assignment methods' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judge) { create(:user, :with_judge_role) }
    let(:regular_user) { create(:user) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }

    describe '#judge_assigned?' do
      it 'returns false for non-judge users' do
        expect(contest_instance.judge_assigned?(regular_user)).to be false
      end

      it 'returns false for unassigned judges' do
        expect(contest_instance.judge_assigned?(judge)).to be false
      end

      it 'returns true for assigned judges' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        expect(contest_instance.judge_assigned?(judge)).to be true
      end

      it 'returns false for inactive assignments' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: false)
        expect(contest_instance.judge_assigned?(judge)).to be false
      end
    end

    describe '#judge_assigned_to_round?' do
      let!(:judging_assignment) do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      end

      it 'returns false when judge is not assigned to round' do
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns true when judge is assigned to round' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be true
      end

      it 'returns false when round assignment is inactive' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: false)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns false when contest assignment is inactive' do
        judging_assignment.update(active: false)
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end
    end
  end

  # Judging Status Methods
  describe 'judging status methods' do
    let(:contest_instance) { create(:contest_instance) }

    describe '#judging_open?' do
      context 'when there is no current judging round' do
        it 'returns false' do
          expect(contest_instance.judging_open?).to be false
        end
      end

      context 'when contest instance dates are invalid' do
        let(:contest_instance) { create(:contest_instance, date_open: 1.day.from_now, date_closed: 2.days.from_now) }
        let!(:judging_round) {
          create(:judging_round,
                contest_instance: contest_instance,
                start_date: Time.current,
                end_date: 3.days.from_now,
                active: true)
        }

        it 'returns false when current time is before date_open' do
          expect(contest_instance.judging_open?).to be false
        end

        it 'returns false when current time is after date_closed' do
          travel_to 3.days.from_now do
            expect(contest_instance.judging_open?).to be false
          end
        end
      end

      context 'when contest instance dates are valid' do
        let(:contest_instance) { create(:contest_instance, date_open: 1.day.ago, date_closed: 2.days.from_now) }

        context 'with an active judging round' do
          let!(:judging_round) {
            create(:judging_round,
                  contest_instance: contest_instance,
                  start_date: 1.day.ago,
                  end_date: 1.day.from_now,
                  active: true)
          }

          it 'returns true when within judging round dates' do
            expect(contest_instance.judging_open?).to be true
          end

          it 'returns false when before judging round start_date' do
            travel_to 2.days.ago do
              expect(contest_instance.judging_open?).to be false
            end
          end

          it 'returns false when after judging round end_date' do
            travel_to 2.days.from_now do
              expect(contest_instance.judging_open?).to be false
            end
          end
        end

        context 'with an inactive judging round' do
          let!(:judging_round) {
            create(:judging_round,
                  contest_instance: contest_instance,
                  start_date: 1.day.ago,
                  end_date: 1.day.from_now,
                  active: false)
          }

          it 'returns false even when within judging round dates' do
            expect(contest_instance.judging_open?).to be false
          end
        end
      end
    end

    describe '#judge_evaluations_complete?' do
      context 'when there are no judging rounds' do
        it 'returns false' do
          expect(contest_instance.judge_evaluations_complete?).to be false
        end
      end

      context 'when there are judging rounds' do
        let!(:round1) {
          create(:judging_round,
                contest_instance: contest_instance,
                round_number: 1,
                start_date: 1.day.from_now,
                end_date: 2.days.from_now,
                completed: false)
        }

        it 'returns false when the last round is not completed' do
          expect(contest_instance.judge_evaluations_complete?).to be false
        end

        it 'returns true when the last round is completed' do
          round1.update(completed: true)
          expect(contest_instance.judge_evaluations_complete?).to be true
        end

        context 'with multiple rounds' do
          let!(:round2) {
            create(:judging_round,
                  contest_instance: contest_instance,
                  round_number: 2,
                  start_date: 3.days.from_now,
                  end_date: 4.days.from_now,
                  completed: false)
          }

          it 'returns false when the last round is not completed, even if earlier rounds are' do
            round1.update(completed: true)
            expect(contest_instance.judge_evaluations_complete?).to be false
          end

          it 'returns true when the last round is completed, regardless of earlier rounds' do
            round1.update(completed: false)
            round2.update(completed: true)
            expect(contest_instance.judge_evaluations_complete?).to be true
          end
        end
      end
    end
  end

  # Class Methods
  describe '.active_and_open' do
    let!(:active_open_contest) { create(:contest_instance, date_open: 1.day.ago, date_closed: 1.day.from_now) }
    let!(:inactive_contest) { create(:contest_instance, :inactive) }
    let!(:archived_contest) { create(:contest_instance, :archived) }
    let!(:future_contest) { create(:contest_instance, date_open: 1.day.from_now, date_closed: 2.days.from_now) }
    let!(:past_contest) { create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago) }

    it 'returns only active contests within the date range' do
      expect(ContestInstance.active_and_open).to contain_exactly(active_open_contest)
    end
  end

  describe '.for_class_level' do
    let(:class_level1) { create(:class_level) }
    let(:class_level2) { create(:class_level) }
    let!(:contest_instance) { create(:contest_instance, class_levels: [ class_level1 ]) }
    let!(:contest_instance2) { create(:contest_instance, class_levels: [ class_level1, class_level2 ]) }
    let!(:contest_instance3) { create(:contest_instance, class_levels: [ class_level2 ]) }

    it 'returns contests matching the specified class level' do
      expect(ContestInstance.for_class_level(class_level1.id)).to include(contest_instance, contest_instance2)
    end

    it 'returns contests matching the specified class level (class_level2)' do
      expect(ContestInstance.for_class_level(class_level2.id)).to include(contest_instance2, contest_instance3)
    end

    it 'returns unique contests when multiple class levels are associated' do
      result = ContestInstance.for_class_level(class_level1.id)
      expect(result.count).to eq(result.uniq.count)
    end

    it 'does not return contests without the specified class level' do
      expect(ContestInstance.for_class_level(class_level2.id)).not_to include(contest_instance)
    end
  end

  describe '.available_for_profile' do
    let(:profile) { create(:profile) }
    let(:other_profile) { create(:profile) }
    let(:contest_instance_with_limit) { create(:contest_instance, maximum_number_entries_per_applicant: 1) }
    let(:contest_instance_high_limit) { create(:contest_instance, maximum_number_entries_per_applicant: 1000) }
    let(:contest_instance_closed) { create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago) }

    context 'when the profile has not reached the maximum number of entries' do
      it 'includes the contest instance' do
        expect(ContestInstance.available_for_profile(profile)).to include(contest_instance_with_limit)
      end
    end

    context 'when the profile has reached the maximum number of entries' do
      before do
        create(:entry, profile: profile, contest_instance: contest_instance_with_limit)
      end

      it 'excludes the contest instance' do
        expect(ContestInstance.available_for_profile(profile)).not_to include(contest_instance_with_limit)
      end

      it 'includes the contest instance for other profiles' do
        expect(ContestInstance.available_for_profile(other_profile)).to include(contest_instance_with_limit)
      end
    end

    context 'when the profile has soft-deleted entries' do
      before do
        entry = create(:entry, profile: profile, contest_instance: contest_instance_with_limit)
        entry.update(deleted: true)
      end

      it 'includes the contest instance' do
        expect(ContestInstance.available_for_profile(profile)).to include(contest_instance_with_limit)
      end
    end

    context 'when the contest instance has a high entry limit' do
      before do
        create_list(:entry, 999, profile: profile, contest_instance: contest_instance_high_limit)
      end

      it 'includes the contest instance as limit is not reached' do
        expect(ContestInstance.available_for_profile(profile)).to include(contest_instance_high_limit)
      end

      it 'excludes the contest instance when limit is reached' do
        create(:entry, profile: profile, contest_instance: contest_instance_high_limit)
        expect(ContestInstance.available_for_profile(profile)).not_to include(contest_instance_high_limit)
      end
    end

    context 'when the contest instance is closed' do
      it 'includes the contest instance if active_and_open is not applied' do
        expect(ContestInstance.available_for_profile(profile)).to include(contest_instance_closed)
      end
    end
  end
end
