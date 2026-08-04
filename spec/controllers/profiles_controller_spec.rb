# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:contest_instance) { create(:contest_instance) }
  let(:profile_attributes) do
    attributes_for(:profile).merge(
      class_level_id: create(:class_level).id,
      school_id: create(:school).id,
      campus_id: create(:campus).id
    )
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
  end
end
