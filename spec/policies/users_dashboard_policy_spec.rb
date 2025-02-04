# spec/policies/users_dashboard_policy_spec.rb
require 'rails_helper'

RSpec.describe UsersDashboardPolicy do
  subject { described_class.new(user, :users_dashboard) }

  let(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }
  let(:judge_role) { create(:role, kind: 'Judge') }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:manager_role) { create(:role, kind: 'Collection Manager') }

  context 'when user has Axis Mundi role' do
    let(:user) { create(:user) }

    before { create(:user_role, user: user, role: axis_mundi_role) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
  end

  context 'when user has Judge role' do
    let(:user) { create(:user) }

    before { create(:user_role, user: user, role: judge_role) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
  end

  context 'when user has Collection Administrator role' do
    let(:user) { create(:user) }

    before { create(:user_role, user: user, role: admin_role) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
  end

  context 'when user has Collection Manager role' do
    let(:user) { create(:user) }

    before { create(:user_role, user: user, role: manager_role) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
  end

  describe 'Scope' do
    subject { UsersDashboardPolicy::Scope.new(user, User).resolve }

    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    context 'when user has Axis Mundi role' do
      let(:user) { create(:user) }

      before { create(:user_role, user: user, role: axis_mundi_role) }

      it 'shows all users' do
        expect(subject).to include(user1, user2)
      end
    end

    context 'when user has other roles' do
      let(:user) { create(:user) }

      before do
        create(:user_role, user: user, role: judge_role)
        create(:user_role, user: user, role: admin_role)
        create(:user_role, user: user, role: manager_role)
      end

      it 'shows no users' do
        expect(subject).to be_empty
      end
    end
  end
end
