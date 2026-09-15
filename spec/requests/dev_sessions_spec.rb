# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dev browser login', type: :request do
  let!(:admin) { create(:user, :axis_mundi, email: 'rsmoke@umich.edu', uniqname: 'rsmoke', uid: 'rsmoke') }
  let!(:judge) { create(:user, :with_judge_role, email: 'judge@umich.edu', uniqname: 'judgeuid') }

  describe 'GET /dev/sessions' do
    it 'lists existing users for local sign-in' do
      get dev_sessions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Local browser login')
      expect(response.body).to include('Sign in as rsmoke@umich.edu')
      expect(response.body).to include('Sign in as judge@umich.edu')
    end

    it 'filters the user list' do
      get dev_sessions_path, params: { q: 'judgeuid' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sign in as judge@umich.edu')
      expect(response.body).not_to include('Sign in as rsmoke@umich.edu')
    end

    it 'returns not found when the host is not localhost' do
      host! 'evaluate.lsa.umich.edu'

      get dev_sessions_path

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Sign in as rsmoke@umich.edu')
    end

    it 'returns not found when the client is not local' do
      get dev_sessions_path, env: { 'REMOTE_ADDR' => '8.8.8.8' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found when the environment is not development or test' do
      allow(DevBrowserLogin).to receive(:env_allowed?).and_return(false)

      get dev_sessions_path

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /dev/sessions' do
    it 'signs in by user id and follows the usual post-login path' do
      post dev_sessions_path, params: { user_id: admin.id }

      expect(controller.current_user).to eq(admin)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Dev browser login: signed in as rsmoke@umich.edu.')
    end

    it 'signs in a judge by email and sends them to the judge dashboard' do
      post dev_sessions_path, params: { login: 'judge@umich.edu' }

      expect(controller.current_user).to eq(judge)
      expect(response).to redirect_to(judge_dashboard_path)
    end

    it 'signs in by uniqname' do
      post dev_sessions_path, params: { login: 'rsmoke' }

      expect(controller.current_user).to eq(admin)
    end

    it 'replaces an existing session when switching users' do
      sign_in admin

      post dev_sessions_path, params: { user_id: judge.id }

      expect(controller.current_user).to eq(judge)
    end

    it 'does not sign in when no user matches' do
      post dev_sessions_path, params: { login: 'missing-user' }

      expect(controller.current_user).to be_nil
      expect(response).to redirect_to(dev_sessions_path(q: 'missing-user'))
      follow_redirect!
      expect(response.body).to include('No matching local user was found.')
    end

    it 'does not sign in when the host is not localhost' do
      host! 'evaluate.lsa.umich.edu'

      post dev_sessions_path, params: { user_id: admin.id }

      expect(controller.current_user).to be_nil
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'entry points' do
    it 'shows a local login link on the homepage' do
      get root_path

      expect(response.body).to include('Local browser login')
      expect(response.body).to include(dev_sessions_path)
    end

    it 'hides the local login link when the picker is not allowed' do
      allow(DevBrowserLogin).to receive(:allowed?).and_return(false)

      get root_path

      expect(response.body).not_to include('Local browser login')
    end
  end
end
