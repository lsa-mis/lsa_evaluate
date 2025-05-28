require 'rails_helper'

RSpec.describe ContestInstancePolicy do
  subject { described_class.new(user, contest_instance) }

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:container_admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }

  context 'for a user with container role' do
    let(:user) { create(:user) }

    before do
      create(:assignment, container: container, user: user, role: container_admin_role)
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:manage_judges) }

    describe 'view_judging_results?' do
      it 'permits viewing results' do
        expect(subject.view_judging_results?).to be true
      end
    end
  end

  context 'for a user with axis mundi role' do
    let(:user) { create(:user) }

    before do
      create(:user_role, user: user, role: axis_mundi_role)
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:manage_judges) }

    describe 'view_judging_results?' do
      it 'permits viewing results' do
        expect(subject.view_judging_results?).to be true
      end
    end
  end

  context 'for a judge' do
    let(:user) { create(:user, :with_judge_role) }

    before do
      create(:judging_assignment, user: user, contest_instance: contest_instance)
    end

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
    it { is_expected.not_to permit_action(:manage_judges) }

    describe 'view_judging_results?' do
      context 'when judge evaluations are complete' do
        before do
          create(:judging_round, contest_instance: contest_instance, completed: true)
        end

        it 'permits viewing results' do
          expect(subject.view_judging_results?).to be true
        end
      end

      context 'when judge evaluations are not complete' do
        before do
          create(:judging_round, contest_instance: contest_instance, completed: false)
        end

        it 'does not permit viewing results' do
          expect(subject.view_judging_results?).to be false
        end
      end
    end
  end

  context 'for a regular user' do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
    it { is_expected.not_to permit_action(:manage_judges) }

    describe 'view_judging_results?' do
      it 'does not permit viewing results' do
        expect(subject.view_judging_results?).to be false
      end
    end
  end

  context 'when user is nil' do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
    it { is_expected.not_to permit_action(:manage_judges) }

    describe 'view_judging_results?' do
      it 'does not permit viewing results' do
        expect(subject.view_judging_results?).to be false
      end
    end
  end
end
