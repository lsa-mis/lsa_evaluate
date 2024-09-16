# spec/support/auth_helpers.rb
module AuthHelpers
  def mock_login(info)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: '12345678',
      info: {
        email: info[:email],
        name: info[:name],
        uniqname: info[:uniqname]
      }
    })
    post user_saml_omniauth_callback_path
  end
end
