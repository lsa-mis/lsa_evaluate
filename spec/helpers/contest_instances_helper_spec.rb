# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstancesHelper, type: :helper do
  describe '#contest_instance_setup_steps' do
    it 'marks earlier steps complete and the current step current' do
      steps = helper.contest_instance_setup_steps(:review_process)

      expect(steps.map { |step| [ step[:key], step[:state] ] }).to eq(
        [
          [ :contest_details, :complete ],
          [ :questions, :complete ],
          [ :review_process, :current ],
          [ :dashboard, :upcoming ]
        ]
      )
    end

    it 'marks the first step current and later steps upcoming' do
      steps = helper.contest_instance_setup_steps(:contest_details)

      expect(steps.map { |step| [ step[:key], step[:state] ] }).to eq(
        [
          [ :contest_details, :current ],
          [ :questions, :upcoming ],
          [ :review_process, :upcoming ],
          [ :dashboard, :upcoming ]
        ]
      )
    end

    it 'marks the last step current and earlier steps complete' do
      steps = helper.contest_instance_setup_steps(:dashboard)

      expect(steps.map { |step| step[:state] }).to eq([ :complete, :complete, :complete, :current ])
    end

    it 'treats an unknown step as the first step' do
      steps = helper.contest_instance_setup_steps(:not_a_step)

      expect(steps.first[:state]).to eq(:current)
      expect(steps.drop(1).map { |step| step[:state] }).to eq([ :upcoming, :upcoming, :upcoming ])
    end
  end

  describe '#contest_instance_active_tab' do
    it 'returns summary by default' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))

      expect(helper.contest_instance_active_tab).to eq('summary')
    end

    it 'returns judging-results when sort_judge_id is present' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(sort_judge_id: '4')
      )

      expect(helper.contest_instance_active_tab).to eq('judging-results')
    end

    it 'returns explicit tab param when valid' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(tab: 'entries')
      )

      expect(helper.contest_instance_active_tab).to eq('entries')
    end

    it 'ignores invalid tab params and falls back to summary' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(tab: 'not-a-tab')
      )

      expect(helper.contest_instance_active_tab).to eq('summary')
    end

    it 'prefers judging-results over an invalid tab when sorting by judge' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(tab: 'not-a-tab', sort_judge_id: '4')
      )

      expect(helper.contest_instance_active_tab).to eq('judging-results')
    end
  end

  describe '#contest_instance_tab_active?' do
    it 'is true only for the active tab' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(tab: 'manage-judges')
      )

      expect(helper.contest_instance_tab_active?('manage-judges')).to be true
      expect(helper.contest_instance_tab_active?('summary')).to be false
    end
  end
end
