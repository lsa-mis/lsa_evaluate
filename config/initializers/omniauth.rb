# frozen_string_literal: true

# Configure OmniAuth to work properly with CSRF protection
# This is needed because the omniauth-rails_csrf_protection gem requires
# proper configuration to work with SAML callbacks

# Set the full_host for OmniAuth to ensure proper callback URLs
OmniAuth.config.full_host = lambda do |env|
  scheme = env['rack.url_scheme']
  host = env['HTTP_HOST'] || env['SERVER_NAME'] || env['SERVER_ADDR']
  port = env['SERVER_PORT']

  port = nil if (scheme == 'https' && port == '443') || (scheme == 'http' && port == '80')

  if port
    "#{scheme}://#{host}:#{port}"
  else
    "#{scheme}://#{host}"
  end
end

# Configure OmniAuth to use a custom request phase for SAML
# This helps with CSRF protection while still allowing SAML callbacks to work
OmniAuth.config.request_validation_phase = lambda do |env|
  # Skip CSRF validation for SAML callbacks
  if env['PATH_INFO'] =~ %r{/auth/saml/callback}
    # Still perform other validations if needed
    # But skip CSRF token validation
  else
    # For all other OmniAuth paths, use the default CSRF protection
    OmniAuth::RailsCsrfProtection::TokenVerifier.new.call(env)
  end
end

# Set a custom path prefix for OmniAuth
# This is optional but can be useful for routing
OmniAuth.config.path_prefix = '/users/auth'
