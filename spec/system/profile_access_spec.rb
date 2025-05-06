require 'rails_helper'

RSpec.describe 'Profile Access', type: :system do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:profile) { create(:profile) }
  let(:profile_owner) { profile.user }
  let(:axis_mundi_role) { create(:role, kind: 'Axis mundi') }
  let(:collection_admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:regular_user) { create(:user) }
  let(:axis_mundi_user) { create(:user, :axis_mundi) }
  let(:collection_admin) { create(:user, :with_collection_admin_role) }
  let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

  before do
    create(:assignment, user: collection_admin, container: container, role: collection_admin_role)
    entry
  end

  context 'when user is the profile owner' do
    before do
      sign_in profile_owner
      visit applicant_profile_entry_path(entry)
    end

    it 'allows access to view their own profile' do
      expect(page).to have_content(profile.preferred_first_name)
      expect(page).to have_content(profile.preferred_last_name)
    end
  end

  context 'when user is an Axis Mundi' do
    before do
      sign_in axis_mundi_user
      visit applicant_profile_entry_path(entry)
    end

    it 'allows access to the profile view' do
      expect(page).to have_content(profile.preferred_first_name)
      expect(page).to have_content(profile.preferred_last_name)
    end
  end

  context 'when user is a Collection Admin' do
    before do
      sign_in collection_admin
      visit applicant_profile_entry_path(entry)
    end

    it 'allows access to the profile view' do
      expect(page).to have_content(profile.preferred_first_name)
      expect(page).to have_content(profile.preferred_last_name)
    end
  end

  context 'when user is neither Axis Mundi nor Collection Admin' do
    before do
      sign_in regular_user
      visit applicant_profile_entry_path(entry)
    end

    it 'redirects with an unauthorized message' do
      expect(page).to have_content('!!! Not authorized !!!')
    end
  end
end
