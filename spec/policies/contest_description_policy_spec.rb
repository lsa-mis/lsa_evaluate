# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestDescriptionPolicy do
  subject { described_class.new(user, contest_description) }

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:other_container) { create(:container) }
  let(:other_contest_description) { create(:contest_description, :active, container: other_container) }

  describe 'action permissions' do
    context 'for a visitor' do
      let(:user) { nil }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:eligibility_rules) }
      it { is_expected.not_to permit_action(:create) }
      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'for a Collection Administrator of the container' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'for a Collection Manager of the container' do
      let(:user) { create(:user) }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      before do
        create(:assignment, user: user, container: container, role: manager_role)
      end

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'for an unrelated user' do
      let(:user) { create(:user) }

      it { is_expected.not_to permit_action(:create) }
      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'for Axis mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
    end
  end

  describe ContestDescriptionPolicy::Scope do
    subject { described_class.new(user, ContestDescription).resolve }

    let!(:assigned_description) { contest_description }
    let!(:unassigned_description) { other_contest_description }
    let!(:contest_instance) { create(:contest_instance, contest_description: assigned_description) }

    context 'for Axis mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it 'returns all contest descriptions' do
        expect(subject).to include(assigned_description, unassigned_description)
      end
    end

    context 'for a judge with an active judging assignment' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
      end

      it 'returns only contest descriptions they are assigned to judge' do
        expect(subject).to include(assigned_description)
        expect(subject).not_to include(unassigned_description)
      end
    end

    context 'for a judge with only an inactive judging assignment' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, :inactive, user: user, contest_instance: contest_instance)
      end

      it 'excludes contest descriptions with inactive assignments' do
        expect(subject).not_to include(assigned_description, unassigned_description)
      end
    end

    context 'for a container staff member without the Judge role' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it 'returns contest descriptions in their containers only' do
        expect(subject).to include(assigned_description)
        expect(subject).not_to include(unassigned_description)
      end
    end

    context 'for a user who is both a judge and container staff' do
      let(:user) { create(:user, :with_judge_role) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let!(:staff_only_description) do
        create(:contest_description, :active, container: container, name: 'Staff Only Contest')
      end

      before do
        create(:assignment, user: user, container: container, role: admin_role)
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
      end

      it 'uses the judge scope branch and does not include unassigned container contests' do
        expect(subject).to include(assigned_description)
        expect(subject).not_to include(staff_only_description)
        expect(subject).not_to include(unassigned_description)
      end
    end

    context 'for a user with no container assignments or judge role' do
      let(:user) { create(:user) }

      it 'returns no contest descriptions' do
        expect(subject).to be_empty
      end
    end
  end
end
