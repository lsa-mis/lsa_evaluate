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
end
