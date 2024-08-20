require 'rails_helper'

RSpec.describe ContainerPolicy do
  subject { described_class.new(user, container) }

  # Create the container before each test
  let!(:container) { create(:container) } # Ensure container is saved to the database
  let!(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }
  let!(:container_admin_role) { create(:role, kind: 'Container Administrator') }
  let!(:container_manager_role) { create(:role, kind: 'Container Manager') }
  let(:axis_mundi_user) { create(:user) }
  let(:creator) { create(:user, person_affiliation: 'employee') }

  before do
    # Ensure the roles and assignments are created after the container is available
    create(:assignment, container: container, user: creator, role: container_admin_role)
  end

  context 'for an employee user' do
    let(:user) { creator }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
  end

  context 'for a non-employee user' do
    let(:user) { create(:user, person_affiliation: 'student') }

    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
  end

  context 'for an employee user who did not create the container but has a manager role' do
    let(:user) { create(:user, person_affiliation: 'employee') }

    before do
      create(:assignment, container: container, user: user, role: container_manager_role)
    end

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
  end

  context 'for an Axis Mundi user' do
    let(:user) { axis_mundi_user }

    before do
      create(:user_role, user: user, role: axis_mundi_role)
    end

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end
end
