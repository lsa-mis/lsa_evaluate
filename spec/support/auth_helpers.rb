# spec/support/auth_helpers.rb
module AuthHelpers
  # def mock_login(user)
  #   allow(controller).to receive(:current_user).and_return(user)
  #   allow(controller).to receive(:user_signed_in?).and_return(true)
  # end
  #
  def mock_login(info)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
                                                                provider: 'saml',
                                                                uid: '12345678',
                                                                info:
                                                              })
    post user_saml_omniauth_callback_path
  end
end
