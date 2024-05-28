# frozen_string_literal: true

module Users
  # The SessionsController class handles user sessions and authentication.
  class SessionsController < Devise::SessionsController
    # Destroys the user session and preserves the SAML UID and session index in the session.
    def destroy
      saml_uid = session['saml_uid']
      saml_session_index = session['saml_session_index']
      super do
        session['saml_uid'] = saml_uid
        session['saml_session_index'] = saml_session_index
      end
    end

    # Determines the path to redirect to after signing out.
    # If the SAML UID and session index are present in the session, it redirects to the SAML Omniauth authorize path
    # with the 'spslo' parameter
    # Otherwise, it calls the super method to get the default redirect path.
    def after_sign_out_path_for(_)
      if session['saml_uid'] && session['saml_session_index']
        "#{user_saml_omniauth_authorize_path}/spslo"
      else
        super
      end
    end
  end
end
