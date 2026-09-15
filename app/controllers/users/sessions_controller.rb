# frozen_string_literal: true

module Users
  # The SessionsController class handles user sessions and authentication.
  class SessionsController < Devise::SessionsController
    # Heartbeat must answer 401 for expired sessions instead of redirecting to sign-in.
    # Sign-in must not run ApplicationController's authenticate_user! / Sentry user
    # lookup, or a password POST would authenticate before we can reject it.
    skip_before_action :authenticate_user!, only: [ :new, :create, :heartbeat ]
    skip_before_action :set_sentry_context, only: [ :new, :create, :heartbeat ]

    def create
      unless DatabaseAuthentication.enabled?
        warden.logout(resource_name) if warden.authenticated?(resource_name)
        redirect_to new_user_session_path, alert: 'Please sign in with your U-M account.'
        return
      end

      super
    end

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

    def heartbeat
      if user_signed_in?
        head :ok
      else
        head :unauthorized
      end
    end

    protected

    def allow_params_authentication!
      super if DatabaseAuthentication.enabled?
    end
  end
end
