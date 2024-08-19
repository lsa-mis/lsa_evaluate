require 'rails_helper'

RSpec.describe ProfilePolicy do
  subject { described_class.new(user, profile) }

  let(:profile) do
    create(:profile, accepted_financial_aid_notice: true, first_name: 'John', last_name: 'Doe',
                     umid: '12345678', grad_date: Date.today + 1.year, degree: 'Bachelor',
                     class_level_id: create(:class_level).id, campus_id: create(:campus).id,
                     school_id: create(:school).id, home_address: create(:address),
                     campus_address: create(:address))
  end

  let(:axis_mundi_role) { create(:role, kind: 'Axis Mundi') }
  let(:axis_mundi_user) { create(:user) }
  let(:profile_owner) { profile.user }

  context 'for the profile owner' do
    let(:user) { profile_owner }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context 'for a user with Axis Mundi role' do
    let(:user) { axis_mundi_user }

    before do
      create(:user_role, user: user, role: axis_mundi_role)
    end

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context 'for a non-owner user without Axis Mundi role' do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end
end
