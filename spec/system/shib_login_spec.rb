# frozen_string_literal: true

# spec/system/shib_login_spec.rb

require 'rails_helper'

RSpec.describe 'Shibboleth', type: :request do
  describe 'login success -' do
    it 'displays user avatar' do
      user = create(:user)
      mock_login({
                   email: user.email,
                   name: user.display_name,
                   uniqname: user.uniqname
                 })
      raise "Expected a redirect but got #{response.status}" unless response.redirect?

      follow_redirect!
      expect(response.body).to include('id="avatar"')
    end
  end

  describe 'login failure -' do
    it 'does not displays user avatar' do
      user = create(:user)
      mock_login({
                   email: 'kielbasa',
                   name: user.display_name,
                   uniqname: user.uniqname
                 })
      expect(response.body).not_to include('id="avatar"')
    end
  end
end
