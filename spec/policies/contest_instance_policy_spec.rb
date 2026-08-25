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

  # Container-role gated admin actions (CSV export + private invite management)
  shared_examples 'container role gated admin action' do |action|
    let(:container) { contest_instance.contest_description.container }

    context 'when user is nil' do
      let(:user) { nil }

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is a Collection Administrator for the container' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it "permits #{action}" do
        expect(subject).to permit_action(action)
      end
    end

    context 'when user is a Collection Manager for the container' do
      let(:user) { create(:user) }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      before do
        create(:assignment, user: user, container: container, role: manager_role)
      end

      it "permits #{action}" do
        expect(subject).to permit_action(action)
      end
    end

    context 'when user is Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it "permits #{action}" do
        expect(subject).to permit_action(action)
      end
    end

    context 'when user is a Collection Administrator for a different container' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let(:other_container) { create(:container) }

      before do
        create(:assignment, user: user, container: other_container, role: admin_role)
      end

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is a judge assigned to the contest instance' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance)
      end

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end

    context 'when user is an unrelated applicant' do
      let(:user) { create(:user) }

      it "forbids #{action}" do
        expect(subject).not_to permit_action(action)
      end
    end
  end

  describe '#export_entries?' do
    include_examples 'container role gated admin action', :export_entries
  end

  describe '#manage_invitations?' do
    include_examples 'container role gated admin action', :manage_invitations
  end

  describe '#regenerate_access_token?' do
    include_examples 'container role gated admin action', :regenerate_access_token
  end

  describe '#send_invite_emails?' do
    include_examples 'container role gated admin action', :send_invite_emails
  end

  describe '#view_judging_results?' do
    let(:container) { contest_instance.contest_description.container }

    context 'when user is nil' do
      let(:user) { nil }

      it 'forbids viewing judging results' do
        expect(subject).not_to permit_action(:view_judging_results)
      end
    end

    context 'when user is Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it 'permits viewing judging results' do
        expect(subject).to permit_action(:view_judging_results)
      end
    end

    context 'when user has a container role' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it 'permits viewing judging results even when evaluations are incomplete' do
        expect(contest_instance.judge_evaluations_complete?).to be false
        expect(subject).to permit_action(:view_judging_results)
      end
    end

    context 'when user is a judge and evaluations are complete' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance)
        create(:judging_round,
               contest_instance: contest_instance,
               round_number: 1,
               start_date: 2.days.ago,
               end_date: 1.day.ago,
               completed: true)
      end

      it 'permits viewing judging results' do
        expect(contest_instance.judge_evaluations_complete?).to be true
        expect(subject).to permit_action(:view_judging_results)
      end
    end

    context 'when user is a judge but evaluations are incomplete' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance)
        create(:judging_round,
               contest_instance: contest_instance,
               round_number: 1,
               start_date: 1.day.from_now,
               end_date: 2.days.from_now,
               completed: false)
      end

      it 'forbids viewing judging results' do
        expect(contest_instance.judge_evaluations_complete?).to be false
        expect(subject).not_to permit_action(:view_judging_results)
      end
    end

    context 'when user is a Collection Administrator for a different container' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let(:other_container) { create(:container) }

      before do
        create(:assignment, user: user, container: other_container, role: admin_role)
      end

      it 'forbids viewing judging results' do
        expect(subject).not_to permit_action(:view_judging_results)
      end
    end

    context 'when user is an unrelated applicant' do
      let(:user) { create(:user) }

      it 'forbids viewing judging results' do
        expect(subject).not_to permit_action(:view_judging_results)
      end
    end
  end

  describe 'Scope' do
    subject { described_class::Scope.new(user, ContestInstance).resolve }

    let!(:owned_instance) { contest_instance }
    let!(:other_instance) { create(:contest_instance) }

    context 'when user is Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it 'includes all contest instances' do
        expect(subject).to include(owned_instance, other_instance)
      end
    end

    context 'when user has a role on one container' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment,
               user: user,
               container: owned_instance.contest_description.container,
               role: admin_role)
      end

      it 'includes only contest instances for assigned containers' do
        expect(subject).to include(owned_instance)
        expect(subject).not_to include(other_instance)
      end
    end

    context 'when user has no container assignments' do
      let(:user) { create(:user) }

      it 'returns no contest instances' do
        expect(subject).to be_empty
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'returns no contest instances' do
        expect(subject).to be_empty
      end
    end
  end
end
