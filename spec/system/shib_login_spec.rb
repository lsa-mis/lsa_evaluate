# frozen_string_literal: true

require 'rails_helper'

def mock_login(info)
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
                                                              provider: 'saml',
                                                              uid: '12345678',
                                                              info:
                                                            })
  post user_saml_omniauth_callback_path
end

RSpec.describe 'Shibboleth', type: :request do
  describe 'login success - ' do
    it 'displays welcome message on landing page' do
      user = FactoryBot.create(:user)
      mock_login({
                   email: user.email,
                   name: user.display_name,
                   uniqname: user.uniqname
                 })
      raise "Expected a redirect but got #{response.status}" unless response.redirect?

      follow_redirect!
      expect(response.body).to include('How to use LSA Evaluate')
    end
  end

  describe 'login failure - ' do
    it 'displays welcome message on landing page' do
      user = FactoryBot.create(:user)
      mock_login({
                   email: 'kielbasa',
                   name: user.display_name,
                   uniqname: user.uniqname
                 })
      expect(response.body).not_to include('How to use LSA Evaluate')
    end
  end
end
