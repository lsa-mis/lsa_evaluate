# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstancePolicy do
  subject { described_class.new(user, contest_instance) }

  let(:contest_instance) { create(:contest_instance, date_open: 10.days.ago, date_closed: 5.days.ago) }

  # Judging-open gating: policies that require user to be a judge AND judging_open?(user)
  shared_examples 'judging_open? gated judge action' do |action|
    context 'when user is nil' do
      let(:user) { nil }

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is not a judge for this instance' do
      let(:user) { create(:user, :with_judge_role) }

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is a judge but not assigned to the current round' do
      let(:user) { create(:user, :with_judge_role) }
      let!(:judging_round) do
        create(:judging_round,
          contest_instance: contest_instance,
          active: true,
          start_date: 4.days.ago,
          end_date: 2.days.from_now
        )
      end

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
        # No round_judge_assignment -> judging_open?(user) is false
      end

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when there is no current judging round' do
      let(:user) { create(:user, :with_judge_role) }
      let!(:judging_round) do
        create(:judging_round,
          contest_instance: contest_instance,
          active: true,
          start_date: 1.day.from_now,
          end_date: 3.days.from_now
        )
      end

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: user, judging_round: judging_round, active: true)
      end

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is a judge and judging is open for them' do
      let(:user) { create(:user, :with_judge_role) }
      let!(:judging_round) do
        create(:judging_round,
          contest_instance: contest_instance,
          active: true,
          start_date: 4.days.ago,
          end_date: 2.days.from_now
        )
      end

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: user, judging_round: judging_round, active: true)
      end

      it "permits #{action}" do
        expect(subject).to permit_action(action)
      end
    end
  end

  describe '#notify_completed?' do
    include_examples 'judging_open? gated judge action', :notify_completed
  end

  describe '#update_rankings?' do
    include_examples 'judging_open? gated judge action', :update_rankings
  end

  describe '#finalize_rankings?' do
    include_examples 'judging_open? gated judge action', :finalize_rankings
  end
end
