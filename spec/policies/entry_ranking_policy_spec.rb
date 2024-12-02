require 'rails_helper'

RSpec.describe EntryRankingPolicy do
  subject { described_class.new(user, entry_ranking) }

  let(:contest_instance) { create(:contest_instance) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:entry_ranking) { build(:entry_ranking, entry: entry, judging_round: judging_round) }

  context 'for an axis mundi user' do
    let(:user) { create(:user, :with_axis_mundi_role) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:show) }
  end

  context 'for an assigned judge' do
    let(:user) { create(:user, :with_judge_role) }
    let!(:judging_assignment) do
      create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
    end
    let!(:round_assignment) do
      create(:round_judge_assignment, user: user, judging_round: judging_round, active: true)
    end

    it { is_expected.to permit_action(:create) }

    context 'when ranking belongs to the judge' do
      let(:entry_ranking) { build(:entry_ranking, user: user, entry: entry, judging_round: judging_round) }

      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:show) }
    end

    context 'when ranking belongs to another judge' do
      let(:other_judge) { create(:user, :with_judge_role) }
      let(:entry_ranking) { build(:entry_ranking, user: other_judge, entry: entry, judging_round: judging_round) }

      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  context 'for an unassigned judge' do
    let(:user) { create(:user, :with_judge_role) }

    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:show) }
  end

  context 'for a regular user' do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:show) }
  end

  describe 'Scope' do
    subject { described_class::Scope.new(user, EntryRanking.all).resolve }

    let!(:contest_instance) { create(:contest_instance) }
    let!(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
    let!(:entry) { create(:entry, contest_instance: contest_instance) }
    let!(:judge1) { create(:user, :with_judge_role) }
    let!(:judge2) { create(:user, :with_judge_role) }
    
    # Create judging assignments for both judges
    let!(:judge1_assignments) do
      create(:judging_assignment, user: judge1, contest_instance: contest_instance, active: true)
      create(:round_judge_assignment, user: judge1, judging_round: judging_round, active: true)
    end
    
    let!(:judge2_assignments) do
      create(:judging_assignment, user: judge2, contest_instance: contest_instance, active: true)
      create(:round_judge_assignment, user: judge2, judging_round: judging_round, active: true)
    end
    
    let!(:ranking1) { create(:entry_ranking, user: judge1, entry: entry, judging_round: judging_round) }
    let!(:ranking2) { create(:entry_ranking, user: judge2, entry: entry, judging_round: judging_round) }

    context 'when user is axis_mundi' do
      let(:user) { create(:user, :with_axis_mundi_role) }

      it 'returns all rankings' do
        expect(subject).to include(ranking1, ranking2)
      end
    end

    context 'when user is an assigned judge' do
      let(:user) { judge1 }

      it 'returns only their rankings' do
        expect(subject).to include(ranking1)
        expect(subject).not_to include(ranking2)
      end
    end

    context 'when user is not a judge' do
      let(:user) { create(:user) }

      it 'returns no rankings' do
        expect(subject).to be_empty
      end
    end
  end
end
