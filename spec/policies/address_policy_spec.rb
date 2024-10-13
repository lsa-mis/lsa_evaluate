# spec/policies/address_policy_spec.rb
require 'rails_helper'

RSpec.describe AddressPolicy do
  subject { described_class.new(user, address) }

  let(:owned_address) { create(:address) }
  let(:other_address) { create(:address) }
  let(:address) { owned_address } # Default address for tests

  let(:address_owner_user) { create(:user) }
  let(:axis_mundi_user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }

  before do
    # Assign the Axis Mundi role to the axis_mundi_user
    create(:user_role, user: axis_mundi_user, role: axis_mundi_role)

    # Create a profile for the address_owner_user with the owned_address as home_address
    create(:profile, user: address_owner_user, home_address: owned_address)
  end

  context 'when user is axis mundi' do
    let(:user) { axis_mundi_user }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:destroy) }
  end

  context 'when user is the owner of the address' do
    let(:user) { address_owner_user }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  context 'when user owns a different address' do
    let(:user) { address_owner_user }
    let(:address) { other_address }

    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:update) }
  end

  context 'when user is not the owner and not axis mundi' do
    let(:user) { other_user }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:new) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:edit) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  context 'when user is nil (not logged in)' do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:new) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:edit) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  describe 'Scope' do
    subject { Pundit.policy_scope(user, Address) }

    let!(:address1) { create(:address) }
    let!(:address2) { create(:address) }

    context 'when user is axis mundi' do
      let(:user) { axis_mundi_user }

      it 'includes all addresses' do
        expect(subject).to include(address1, address2)
      end
    end

    context 'when user is not axis mundi' do
      let(:user) { other_user }

      it 'returns an empty scope' do
        expect(subject).to be_empty
      end
    end
  end
end
