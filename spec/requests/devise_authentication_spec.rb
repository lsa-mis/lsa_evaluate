# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise authentication surfaces', type: :request do
  describe 'registration and password recovery' do
    it 'does not expose a public sign-up page' do
      get '/users/sign_up'

      expect(response).to have_http_status(:not_found)
    end

    it 'does not expose password reset' do
      get '/users/password/new'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /users/sign_in' do
    it 'still allows password login in the test environment' do
      user = create(:user, password: 'passwordpassword')

      post user_session_path, params: { user: { email: user.email, password: 'passwordpassword' } }

      expect(response).to redirect_to(root_path)
      expect(request.env['warden'].user).to eq(user)
    end

    it 'rejects password login when database authentication is disabled' do
      user = create(:user, password: 'passwordpassword')
      allow(DatabaseAuthentication).to receive(:enabled?).and_return(false)

      post user_session_path, params: { user: { email: user.email, password: 'passwordpassword' } }

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq('Please sign in with your U-M account.')

      get applicant_dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
