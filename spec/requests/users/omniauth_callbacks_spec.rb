# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::OmniauthCallbacks', type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:saml] = nil
  end

  describe 'POST /users/auth/saml/callback' do
    it 'creates a user from SAML attributes and syncs affiliations' do
      mock_login(
        email: 'newuser@umich.edu',
        name: 'New User',
        uniqname: 'newuser',
        first_name: 'New',
        last_name: 'User',
        uid: 'newuser'
      )

      expect {
        post user_saml_omniauth_callback_path
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)

      user = User.find_by!(email: 'newuser@umich.edu')
      expect(user.uniqname).to eq('newuser')
      expect(user.first_name).to eq('New')
      expect(user.last_name).to eq('User')
      expect(user.display_name).to eq('New User')
      expect(user.affiliations.pluck(:name).map(&:downcase)).to match_array(%w[member student])
    end

    it 'updates an existing user and replaces stale affiliations' do
      user = create(
        :user,
        email: 'returning@umich.edu',
        uniqname: 'returning',
        first_name: 'Old',
        last_name: 'Name',
        display_name: 'Old Name'
      )
      create(:affiliation, user: user, name: 'faculty')
      create(:affiliation, user: user, name: 'alumni')

      mock_login(
        email: 'returning@umich.edu',
        name: 'Returning User',
        uniqname: 'returning',
        first_name: 'Returning',
        last_name: 'User',
        uid: 'returning'
      )

      expect {
        post user_saml_omniauth_callback_path
      }.not_to change(User, :count)

      expect(response).to redirect_to(root_path)

      user.reload
      expect(user.first_name).to eq('Returning')
      expect(user.last_name).to eq('User')
      expect(user.display_name).to eq('Returning User')
      expect(user.affiliations.pluck(:name).map(&:downcase)).to match_array(%w[member student])
      expect(user.affiliations.pluck(:name).map(&:downcase)).not_to include('faculty', 'alumni')
    end

    it 'connects a U-M account when the user is already signed in' do
      user = create(:user, :student, email: 'signedin@umich.edu', uniqname: 'signedin')
      sign_in user

      mock_login(
        email: 'signedin@umich.edu',
        name: user.display_name,
        uniqname: user.uniqname,
        first_name: user.first_name,
        last_name: user.last_name,
        uid: user.uid
      )

      post user_saml_omniauth_callback_path

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Your U-M account was connected.')
    end

    it 'redirects to sign in when user save fails' do
      mock_login(
        email: 'broken@umich.edu',
        name: 'Broken User',
        uniqname: 'broken',
        first_name: 'Broken',
        last_name: 'User',
        uid: 'broken'
      )

      allow_any_instance_of(User).to receive(:save).and_return(false)
      allow_any_instance_of(User).to receive_message_chain(:errors, :full_messages)
        .and_return(['Email is invalid'])

      expect {
        post user_saml_omniauth_callback_path
      }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('User creation/update failed')
      expect(flash[:alert]).to include('Email is invalid')
    end
  end
end
