require 'rails_helper'

RSpec.describe 'User lookup authorization', type: :request do
  let!(:target_user) do
    create(:user, first_name: 'Ada', last_name: 'Lovelace', email: 'ada@umich.edu', uid: 'adal')
  end

  describe 'GET /users/lookup' do
    it 'allows collection staff to search users' do
      employee = create(:user, :employee)
      sign_in employee

      get user_lookup_path, params: { q: 'Ada' }, as: :json

      expect(response).to have_http_status(:ok)
      results = response.parsed_body
      expect(results.first['uid']).to eq('adal')
      expect(results.first['name']).to include('Ada')
    end

    it 'denies applicants who are not collection staff' do
      applicant = create(:user, :student)
      sign_in applicant

      get user_lookup_path, params: { q: 'Ada' }, as: :json

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('!!! Not authorized !!!')
    end

    it 'requires authentication' do
      get user_lookup_path, params: { q: 'Ada' }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /containers/lookup_user' do
    it 'allows axis mundi to search by uid' do
      admin = create(:user, :with_axis_mundi_role)
      sign_in admin

      get lookup_user_containers_path, params: { uid: 'adal' }, as: :json

      expect(response).to have_http_status(:ok)
      results = response.parsed_body
      expect(results.first['uid']).to eq('adal')
      expect(results.first).to include('display_name', 'display_name_and_uid')
    end

    it 'denies applicants who are not collection staff' do
      applicant = create(:user, :student)
      sign_in applicant

      get lookup_user_containers_path, params: { uid: 'adal' }, as: :json

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('!!! Not authorized !!!')
    end

    it 'requires authentication' do
      get lookup_user_containers_path, params: { uid: 'adal' }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
