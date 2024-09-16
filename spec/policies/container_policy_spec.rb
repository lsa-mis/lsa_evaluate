require 'rails_helper'

RSpec.describe ContainerPolicy do
  subject { described_class.new(user, container) }

  let(:container) { create(:container) } # Ensure container is saved to the database
  let!(:container_admin_role) { create(:role, kind: 'Container Administrator') }
  let!(:container_manager_role) { create(:role, kind: 'Container Manager') }
  let!(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }
  let(:creator) { create(:user, :employee) }

  before do
    create(:assignment, container: container, user: creator, role: container_admin_role)
  end

  describe 'action permissions' do
    context 'with an employee user' do
      let(:user) { creator }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
    end

    context 'with a non-employee user' do
      let(:user) { create(:user, :student) }

      it { is_expected.not_to permit_action(:create) }
      it { is_expected.not_to permit_action(:update) }
    end

    context 'with an employee user with a manager role' do
      let(:user) { create(:user, :employee) }

      before do
        create(:assignment, container: container, user: user, role: container_manager_role)
      end

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
    end

    context 'with an Axis Mundi user' do
      let(:user) { create(:user, :employee) }

      before do
        create(:user_role, user: user, role: axis_mundi_role)
      end

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
    end
  end

  describe 'scope' do
    subject { described_class::Scope.new(user, Container) }

    let!(:container1) { create(:container) }
    let!(:container2) { create(:container) }
    let!(:container3) { create(:container) }

    context 'for a user with specific assignments' do
      let!(:user) { create(:user, :employee) }

      before do
        create(:assignment, container: container1, user: user, role: container_admin_role)  # user is an admin for container1
        create(:assignment, container: container2, user: user, role: container_manager_role) # user is a manager for container2
        # user has no assignment for container3
      end

      it 'includes containers where the user is either an admin or manager' do
        containers = subject.resolve
        expect(containers).to include(container1, container2)
        expect(containers).not_to include(container3)
      end
    end

    context 'for a user with no assignments' do
      let!(:user_without_assignments) { create(:user, :student) }

      it 'returns no containers for users with no assignments' do
        containers = described_class::Scope.new(user_without_assignments, Container).resolve
        expect(containers).to be_empty
      end
    end
  end
end
