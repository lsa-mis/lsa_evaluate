# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgingAssignmentPolicy do
  subject { described_class.new(user, judging_assignment) }

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:assigned_judge) { create(:user, :with_judge_role) }
  let(:judging_assignment) do
    create(:judging_assignment, user: assigned_judge, contest_instance: contest_instance, active: true)
  end
  let!(:admin_role) { create(:role, :collection_admin) }

  describe '#show?' do
    context 'when the user is the assigned judge' do
      let(:user) { assigned_judge }

      it { is_expected.to permit_action(:show) }
    end

    context 'when the user has a container admin role' do
      let(:user) { create(:user, :employee) }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it { is_expected.to permit_action(:show) }
    end

    context 'when the user is Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it { is_expected.to permit_action(:show) }
    end

    context 'when the user is another judge' do
      let(:user) { create(:user, :with_judge_role) }

      it { is_expected.not_to permit_action(:show) }
    end
  end

  shared_examples 'admin-only assignment mutation' do |action|
    context 'when the user has a container admin role' do
      let(:user) { create(:user, :employee) }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it { is_expected.to permit_action(action) }
    end

    context 'when the user is Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it { is_expected.to permit_action(action) }
    end

    context 'when the user is the assigned judge' do
      let(:user) { assigned_judge }

      it { is_expected.not_to permit_action(action) }
    end

    context 'when the user is unrelated' do
      let(:user) { create(:user, :employee) }

      it { is_expected.not_to permit_action(action) }
    end
  end

  describe '#create?' do
    include_examples 'admin-only assignment mutation', :create
  end

  describe '#destroy?' do
    include_examples 'admin-only assignment mutation', :destroy
  end
end
