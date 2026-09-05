# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session heartbeat', type: :request do
  describe 'GET /session/heartbeat' do
    it 'returns ok when the user is signed in' do
      sign_in create(:user, :employee)

      get session_heartbeat_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_blank
    end

    it 'returns unauthorized when no user is signed in' do
      get session_heartbeat_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to be_blank
    end
  end
end
