require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '#lookup' do
    let(:current_user) { create(:user) }
    let!(:user1) { create(:user, first_name: 'Alice', last_name: 'Smith', email: 'alice@example.com', uid: 'alice1') }
    let!(:user2) { create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob@example.com', uid: 'bobby') }
    let!(:user3) { create(:user, first_name: 'Carol', last_name: 'Brown', email: 'carol@example.com', uid: 'carolb') }

    before do
      sign_in current_user
    end

    it 'returns users matching the query by name' do
      get :lookup, params: { q: 'Alice' }, format: :json
      results = JSON.parse(response.body)
      expect(results).not_to be_empty
      expect(results.first['name']).to include('Alice')
    end

    it 'returns users matching the query by email' do
      get :lookup, params: { q: 'bob@example.com' }, format: :json
      results = JSON.parse(response.body)
      expect(results).not_to be_empty
      expect(results.first['name']).to include('Bob')
    end

    it 'returns users matching the query by uid' do
      get :lookup, params: { q: 'carolb' }, format: :json
      results = JSON.parse(response.body)
      expect(results).not_to be_empty
      expect(results.first['name']).to include('Carol')
    end

    it 'returns JSON with id, name, and uid' do
      get :lookup, params: { q: 'Alice' }, format: :json
      results = JSON.parse(response.body)
      expect(results).not_to be_empty
      expect(results.first.keys).to include('id', 'name', 'uid')
    end

    it 'limits results to 10' do
      create_list(:user, 15) do |user, i|
        user.first_name = 'Test'
        user.last_name = 'User'
        user.email = "testuser#{i}@example.com"
        user.uid = "testuser#{i}"
        user.save!
      end
      get :lookup, params: { q: 'Test' }, format: :json
      results = JSON.parse(response.body)
      expect(results.length).to be <= 10
    end
  end
end
