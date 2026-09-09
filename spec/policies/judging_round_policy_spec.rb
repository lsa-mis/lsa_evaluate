# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgingRoundPolicy do
  subject { described_class.new(user, judging_round) }

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let!(:admin_role) { create(:role, :collection_admin) }

  describe '#show?' do
    context 'when the user is a pool judge for the contest instance' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
      end

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

    context 'when the user is an unrelated judge' do
      let(:user) { create(:user, :with_judge_role) }

      it { is_expected.not_to permit_action(:show) }
    end
  end

  shared_examples 'container-role or axis mundi action' do |action|
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

    context 'when the user is only a pool judge' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance, active: true)
      end

      it { is_expected.not_to permit_action(action) }
    end

    context 'when the user is unrelated' do
      let(:user) { create(:user, :employee) }

      it { is_expected.not_to permit_action(action) }
    end
  end

  describe '#create?' do
    include_examples 'container-role or axis mundi action', :create
  end

  describe '#update?' do
    include_examples 'container-role or axis mundi action', :update
  end

  describe '#destroy?' do
    include_examples 'container-role or axis mundi action', :destroy
  end

  describe '#complete_round?' do
    include_examples 'container-role or axis mundi action', :complete_round
  end

  describe '#select_entries_for_next_round?' do
    include_examples 'container-role or axis mundi action', :select_entries_for_next_round
  end

  describe '#manage_judges?' do
    include_examples 'container-role or axis mundi action', :manage_judges
  end
end
