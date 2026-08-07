# frozen_string_literal: true

# Encrypts deep-link return paths for SAML RelayState / OmniAuth origin.
# Capability URLs like /c/:token must not be sent to the IdP in cleartext.
# MessageEncryptor keeps the payload opaque and works without a shared cache
# (important when the ACS POST lands on a different app server).
module SamlReturnState
  extend ActiveSupport::Concern

  OPAQUE_PREFIX = 'sr_'
  STATE_PURPOSE = 'saml_return_path'
  STATE_EXPIRES_IN = 30.minutes

  included do
    helper_method :saml_authorize_params
  end

  # Origin passed to SAML so RelayState can restore private-contest (and other) deep links.
  def saml_authorize_params
    origin = session['user_return_to'].presence
    return {} if origin.blank?

    { origin: stash_saml_return_path!(origin) }
  end

  private

  def stash_saml_return_path!(path)
    payload = saml_return_encryptor.encrypt_and_sign(
      { 'path' => path },
      purpose: STATE_PURPOSE,
      expires_in: STATE_EXPIRES_IN
    )
    "#{OPAQUE_PREFIX}#{payload}"
  end

  def resolve_saml_return_state(state)
    return if state.blank?
    return unless state.start_with?(OPAQUE_PREFIX)

    payload = state.delete_prefix(OPAQUE_PREFIX)
    data = saml_return_encryptor.decrypt_and_verify(payload, purpose: STATE_PURPOSE)
    # Expired payloads decrypt to nil (no exception); treat like an invalid RelayState.
    data&.fetch('path', nil)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def saml_return_encryptor
    secret = Rails.application.secret_key_base
    len = ActiveSupport::MessageEncryptor.key_len
    key = ActiveSupport::KeyGenerator.new(secret).generate_key('saml-return-path', len)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
