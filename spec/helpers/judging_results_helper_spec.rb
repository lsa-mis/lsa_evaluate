# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgingResultsHelper, type: :helper do
  describe '#judging_rankings_sort_path' do
    let(:container) { build_stubbed(:container) }
    let(:contest_description) { build_stubbed(:contest_description, container: container) }
    let(:contest_instance) { build_stubbed(:contest_instance, contest_description: contest_description) }
    let(:round) { build_stubbed(:judging_round, id: 7, contest_instance: contest_instance) }
    let(:judge) { build_stubbed(:user, id: 4) }

    before do
      allow(helper).to receive(:controller_name).and_return('contest_instances')
      allow(helper).to receive(:action_name).and_return('show')
    end

    it 'includes tab and sort params for contest instance show' do
      path = helper.judging_rankings_sort_path(
        round, container, contest_description, contest_instance, judge: judge
      )

      expect(path).to eq(
        container_contest_description_contest_instance_path(
          container, contest_description, contest_instance,
          tab: 'judging-results',
          sort_judge_id: 4,
          anchor: 'round-7-rankings'
        )
      )
    end

    it 'uses judging round path on round review page' do
      allow(helper).to receive(:controller_name).and_return('judging_rounds')
      allow(helper).to receive(:action_name).and_return('show')

      path = helper.judging_rankings_sort_path(
        round, container, contest_description, contest_instance, judge: judge
      )

      expect(path).to eq(
        container_contest_description_contest_instance_judging_round_path(
          container, contest_description, contest_instance, round,
          sort_judge_id: 4,
          anchor: 'round-7-rankings'
        )
      )
    end

    it 'respects explicit sort_context over controller inference' do
      allow(helper).to receive(:controller_name).and_return('judging_rounds')
      allow(helper).to receive(:action_name).and_return('show')

      path = helper.judging_rankings_sort_path(
        round, container, contest_description, contest_instance,
        judge: judge,
        sort_context: :contest_instance
      )

      expect(path).to eq(
        container_contest_description_contest_instance_path(
          container, contest_description, contest_instance,
          tab: 'judging-results',
          sort_judge_id: 4,
          anchor: 'round-7-rankings'
        )
      )
    end
  end

  describe '#judging_round_rankings_context' do
    let(:container) { create(:container) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:round) { create(:judging_round, contest_instance: contest_instance, round_number: 1) }
    let(:judge_a) { create(:user, :with_judge_role, first_name: 'Ann', last_name: 'Zebra') }
    let(:judge_b) { create(:user, :with_judge_role, first_name: 'Bob', last_name: 'Able') }
    let!(:entry_high) { create(:entry, contest_instance: contest_instance, title: 'High ranked') }
    let!(:entry_low) { create(:entry, contest_instance: contest_instance, title: 'Low ranked') }
    let!(:entry_unranked) { create(:entry, contest_instance: contest_instance, title: 'Unranked') }

    before do
      create(:judging_assignment, contest_instance: contest_instance, user: judge_a)
      create(:judging_assignment, contest_instance: contest_instance, user: judge_b)
      create(:round_judge_assignment, judging_round: round, user: judge_a)
      create(:round_judge_assignment, judging_round: round, user: judge_b)
      create(:entry_ranking, entry: entry_high, judging_round: round, user: judge_a, rank: 2)
      create(:entry_ranking, entry: entry_high, judging_round: round, user: judge_b, rank: 1)
      create(:entry_ranking, entry: entry_low, judging_round: round, user: judge_a, rank: 5)
      create(:entry_ranking, entry: entry_low, judging_round: round, user: judge_b, rank: 4)
      create(:entry_ranking, entry: entry_unranked, judging_round: round, user: judge_b, rank: 3)
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))
    end

    it 'orders judges by last name then first name' do
      context = helper.judging_round_rankings_context(round)

      expect(context[:judges]).to eq([judge_b, judge_a])
    end

    it 'sorts entries by selected judge rank and places missing ranks last' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(sort_judge_id: judge_a.id.to_s)
      )

      context = helper.judging_round_rankings_context(round)

      expect(context[:entries]).to eq([entry_high, entry_low, entry_unranked])
    end

    it 'falls back to multi-judge rank order when sort_judge_id is absent' do
      context = helper.judging_round_rankings_context(round)

      # Judges ordered Able then Zebra; compare [judge_b rank, judge_a rank]
      # high: [1, 2], low: [4, 5], unranked: [3, INF] => high, unranked, low
      expect(context[:entries]).to eq([entry_high, entry_unranked, entry_low])
    end

    it 'ignores sort_judge_id values that are not assigned to the round' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(sort_judge_id: '999999')
      )

      context = helper.judging_round_rankings_context(round)

      expect(context[:entries]).to eq([entry_high, entry_unranked, entry_low])
    end
  end
end
