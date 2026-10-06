# spec/support/auth_helpers.rb
module AuthHelpers
  def mock_login(info)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: info[:uid] || '12345678',
      info: {
        email: info[:email],
        display_name: info[:display_name],
        uniqname: info[:uniqname],
        first_name: info[:first_name],
        last_name: info[:last_name]
      },
      extra: {
        raw_info: OpenStruct.new(
          attributes: {
            # Okta sends eduPersonPrincipalName (used for email and principal_name)
            # and uid (used for uniqname and uid) once each.
            'urn:oid:1.3.6.1.4.1.5923.1.1.1.6' => [info[:principal_name] || info[:email]],
            'urn:oid:0.9.2342.19200300.100.1.1' => [info[:uid] || info[:uniqname]],
            'urn:oid:2.16.840.1.113730.3.1.241' => [info[:display_name]],
            'urn:oid:2.5.4.42' => [info[:first_name]],
            'urn:oid:2.5.4.4' => [info[:last_name]],
            'urn:oid:1.3.6.1.4.1.5923.1.1.1.1' => ['member', 'student']
          }
        )
      }
    })
  end

  def mock_saml_login(user)
    mock_login({
      email: user.email,
      display_name: user.display_name,
      uniqname: user.uniqname,
      first_name: user.first_name,
      last_name: user.last_name,
      uid: user.uid
    })
  end
end
