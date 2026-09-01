# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:contest_instance) { create(:contest_instance) }
  let(:class_level) { create(:class_level) }
  let(:profile_attributes) do
    {
      legal_first_name: 'Legal',
      legal_last_name: 'Applicant',
      preferred_first_name: 'Preferred',
      preferred_last_name: 'Name',
      umid: format('%08d', rand(10_000_000..99_999_999)),
      class_level_id: class_level.id
    }
  end

  before { sign_in user }

  describe 'POST #create' do
    it 'returns to a pending contest invite after creating the profile' do
      session[:pending_contest_invite_token] = contest_instance.access_token

      post :create, params: { profile: profile_attributes }

      expect(response).to redirect_to(contest_invite_path(token: contest_instance.access_token))
      expect(session[:pending_contest_invite_token]).to be_nil
    end

    it 'uses the applicant dashboard when there is no pending invite' do
      post :create, params: { profile: profile_attributes }

      expect(response).to redirect_to(applicant_dashboard_path)
    end

    it 'persists legal names and ignores removed academic mass-assignment fields' do
      school = create(:school)
      campus = create(:campus)

      post :create, params: {
        profile: profile_attributes.merge(
          school_id: school.id,
          campus_id: campus.id,
          degree: 'MFA',
          major: 'Poetry',
          pen_name: 'Ghost Writer'
        )
      }

      profile = user.reload.profile
      expect(profile).to be_present
      expect(profile.legal_first_name).to eq('Legal')
      expect(profile.legal_last_name).to eq('Applicant')
      expect(profile.class_level_id).to eq(class_level.id)
      expect(profile.school_id).to be_nil
      expect(profile.campus_id).to be_nil
      expect(profile.degree).to be_nil
      expect(profile.major).to be_nil
      expect(profile.pen_name).to be_nil
    end
  end

  describe 'PATCH #update' do
    let!(:profile) { create(:profile, user: user, class_level: class_level) }

    it 'updates permitted identity fields without accepting academic attributes' do
      original_degree = profile.degree
      original_pen_name = profile.pen_name

      patch :update, params: {
        id: profile.id,
        profile: {
          legal_first_name: 'Updated',
          legal_last_name: 'Legal',
          preferred_first_name: 'New',
          preferred_last_name: 'Preferred',
          degree: 'PhD',
          pen_name: 'Should Not Stick'
        }
      }

      profile.reload
      expect(response).to redirect_to(applicant_dashboard_path)
      expect(profile.legal_first_name).to eq('Updated')
      expect(profile.legal_last_name).to eq('Legal')
      expect(profile.preferred_first_name).to eq('New')
      expect(profile.preferred_last_name).to eq('Preferred')
      expect(profile.degree).to eq(original_degree)
      expect(profile.pen_name).to eq(original_pen_name)
    end
  end
end
