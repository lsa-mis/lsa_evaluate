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

  describe '#display_name' do
    it 'returns formatted contest name with dates' do
      contest_description = create(:contest_description, name: 'Test Contest')
      contest_instance = create(:contest_instance,
        contest_description: contest_description,
        date_open: Date.new(2024, 1, 1),
        date_closed: Date.new(2024, 12, 31)
      )
      expect(contest_instance.display_name).to eq('Test Contest - 2024-01-01 to 2024-12-31')
    end
  end

  describe '#current_judging_round' do
    let(:contest_instance) { create(:contest_instance) }

    context 'when there is an active round' do
      let!(:round1) { create(:judging_round, contest_instance: contest_instance, round_number: 1, active: false) }
      let!(:round2) { create(:judging_round, contest_instance: contest_instance, round_number: 2, active: true) }

      it 'returns the active round' do
        expect(contest_instance.current_judging_round).to eq(round2)
      end
    end

    context 'when there is no active round' do
      let!(:round1) { create(:judging_round, contest_instance: contest_instance, round_number: 1, active: false) }
      let!(:round2) { create(:judging_round, contest_instance: contest_instance, round_number: 2, active: false) }

      it 'returns the first round by number' do
        expect(contest_instance.current_judging_round).to eq(round1)
      end
    end
  end

  describe '#judging_open?' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance, active: true) }

    context 'when contest is within dates and round has no specific dates' do
      it 'returns true' do
        contest_instance.update(
          date_open: 1.day.ago,
          date_closed: 1.day.from_now
        )
        expect(contest_instance.judging_open?).to be true
      end
    end

    context 'when contest is within dates but round has specific dates' do
      it 'returns true when within round dates' do
        contest_instance.update(
          date_open: 1.day.ago,
          date_closed: 1.day.from_now
        )
        judging_round.update(
          start_date: 1.hour.ago,
          end_date: 1.hour.from_now
        )
        expect(contest_instance.judging_open?).to be true
      end

      it 'returns false when outside round dates' do
        contest_instance.update(
          date_open: 1.day.ago,
          date_closed: 1.day.from_now
        )
        judging_round.update(
          start_date: 2.days.from_now,
          end_date: 3.days.from_now
        )
        expect(contest_instance.judging_open?).to be false
      end
    end
  end

  describe '#judge_assigned?' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judge) { create(:user, :judge) }
    let(:regular_user) { create(:user) }

    context 'when user is a judge' do
      it 'returns true if assigned to the contest' do
        create(:judging_assignment, contest_instance: contest_instance, user: judge, active: true)
        expect(contest_instance.judge_assigned?(judge)).to be true
      end

      it 'returns false if not assigned to the contest' do
        expect(contest_instance.judge_assigned?(judge)).to be false
      end

      it 'returns false if assignment is inactive' do
        create(:judging_assignment, contest_instance: contest_instance, user: judge, active: false)
        expect(contest_instance.judge_assigned?(judge)).to be false
      end
    end

    context 'when user is not a judge' do
      it 'returns false' do
        expect(contest_instance.judge_assigned?(regular_user)).to be false
      end
    end
  end

  describe '#actual_judging_rounds_count' do
    let(:contest_instance) { create(:contest_instance) }

    it 'returns the count of judging rounds' do
      create_list(:judging_round, 3, contest_instance: contest_instance)
      expect(contest_instance.actual_judging_rounds_count).to eq(3)
    end

    it 'returns 0 when no judging rounds exist' do
      expect(contest_instance.actual_judging_rounds_count).to eq(0)
    end
  end

  describe '#current_round_entries' do
    let(:contest_instance) { create(:contest_instance) }
    let(:entry1) { create(:entry, contest_instance: contest_instance) }
    let(:entry2) { create(:entry, contest_instance: contest_instance) }

    context 'when no current judging round exists' do
      it 'returns an empty relation' do
        expect(contest_instance.current_round_entries).to be_empty
      end
    end

    context 'when in first round' do
      let!(:round1) { create(:judging_round, contest_instance: contest_instance, round_number: 1, active: true) }

      it 'returns all non-deleted entries' do
        entry1.update(deleted: false)
        entry2.update(deleted: true)
        expect(contest_instance.current_round_entries).to contain_exactly(entry1)
      end
    end

    context 'when in second round' do
      let!(:round1) { create(:judging_round, contest_instance: contest_instance, round_number: 1, active: false) }
      let!(:round2) { create(:judging_round, contest_instance: contest_instance, round_number: 2, active: true) }

      it 'returns entries selected from previous round' do
        create(:entry_ranking, entry: entry1, judging_round: round1, selected_for_next_round: true)
        create(:entry_ranking, entry: entry2, judging_round: round1, selected_for_next_round: false)
        expect(contest_instance.current_round_entries).to contain_exactly(entry1)
      end
    end
  end

  describe '#average_rank_for_entry_in_round' do
    let(:contest_instance) { create(:contest_instance) }
    let(:entry) { create(:entry, contest_instance: contest_instance) }
    let(:round) { create(:judging_round, contest_instance: contest_instance) }

    it 'returns the average rank for an entry in a round' do
      create(:entry_ranking, entry: entry, judging_round: round, rank: 1)
      create(:entry_ranking, entry: entry, judging_round: round, rank: 2)
      create(:entry_ranking, entry: entry, judging_round: round, rank: 3)

      expect(contest_instance.average_rank_for_entry_in_round(entry, round)).to eq(2.0)
    end

    it 'returns nil when no rankings exist' do
      expect(contest_instance.average_rank_for_entry_in_round(entry, round)).to be_nil
    end
  end

  describe '#rankings_for_entry_in_round' do
    let(:contest_instance) { create(:contest_instance) }
    let(:entry) { create(:entry, contest_instance: contest_instance) }
    let(:round) { create(:judging_round, contest_instance: contest_instance) }
    let(:judge1) { create(:user, :judge) }
    let(:judge2) { create(:user, :judge) }

    it 'returns all rankings for an entry in a round' do
      ranking1 = create(:entry_ranking, entry: entry, judging_round: round, user: judge1)
      ranking2 = create(:entry_ranking, entry: entry, judging_round: round, user: judge2)

      rankings = contest_instance.rankings_for_entry_in_round(entry, round)
      expect(rankings).to contain_exactly(ranking1, ranking2)
    end

    it 'returns empty when no rankings exist' do
      expect(contest_instance.rankings_for_entry_in_round(entry, round)).to be_empty
    end
  end

  describe '#entry_selected_for_next_round?' do
    let(:contest_instance) { create(:contest_instance) }
    let(:entry) { create(:entry, contest_instance: contest_instance) }
    let(:round) { create(:judging_round, contest_instance: contest_instance) }

    it 'returns true when entry is selected for next round' do
      create(:entry_ranking, entry: entry, judging_round: round, selected_for_next_round: true)
      expect(contest_instance.entry_selected_for_next_round?(entry, round)).to be true
    end

    it 'returns false when entry is not selected for next round' do
      create(:entry_ranking, entry: entry, judging_round: round, selected_for_next_round: false)
      expect(contest_instance.entry_selected_for_next_round?(entry, round)).to be false
    end

    it 'returns false when no ranking exists' do
      expect(contest_instance.entry_selected_for_next_round?(entry, round)).to be false
    end
  end

  describe '#judge_assigned_to_round?' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judge) { create(:user, :judge) }
    let(:round) { create(:judging_round, contest_instance: contest_instance) }

    context 'when judge is assigned to contest' do
      before do
        create(:judging_assignment, contest_instance: contest_instance, user: judge, active: true)
      end

      it 'returns true when judge is assigned to the round' do
        create(:round_judge_assignment, judging_round: round, user: judge, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, round)).to be true
      end

      it 'returns false when judge is not assigned to the round' do
        expect(contest_instance.judge_assigned_to_round?(judge, round)).to be false
      end

      it 'returns false when round assignment is inactive' do
        create(:round_judge_assignment, judging_round: round, user: judge, active: false)
        expect(contest_instance.judge_assigned_to_round?(judge, round)).to be false
      end
    end

    context 'when judge is not assigned to contest' do
      it 'returns false' do
        create(:round_judge_assignment, judging_round: round, user: judge, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, round)).to be false
      end
    end
  end
end
