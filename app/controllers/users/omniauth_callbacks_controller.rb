# frozen_string_literal: true

module Users
  # The `OmniauthCallbacksController` class is responsible for handling callbacks from OmniAuth providers.
  # It inherits from the `Devise::OmniauthCallbacksController` class, which is provided by the Devise gem.
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: :saml
    before_action :set_user, only: :saml
    attr_reader :user, :service

    def saml
      handle_auth('SAML')
    end

    private

    def handle_auth(kind)
      if user_signed_in?
        flash[:notice] = "Your #{kind} account was connected."
        redirect_to edit_user_registration_path
      else
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind:)
      end
    end

    def user_is_stale?
      user_signed_in? && current_user.last_sign_in_at < 15.minutes.ago
    end

    def auth
      request.env['omniauth.auth']
    end

    def set_user
      @user = find_or_initialize_user
      session[:user_email] = @user.email if @user
    end

    def find_or_initialize_user
      if user_signed_in?
        current_user
      elsif (user = User.find_by(email: auth.info.email))
        user
      else
        create_user
      end
    end

    def get_uniqname(email)
      email.split('@').first
    end

    def create_user
      User.create(user_params)
    end

    def user_params
      {
        email: auth.info.email,
        uniqname: get_uniqname(auth.info.email),
        uid: auth.info.uid,
        principal_name: auth.info.principal_name,
        display_name: auth.info.name,
        person_affiliation: auth.info.person_affiliation,
        password: Devise.friendly_token[0, 20]
      }
    end
  end
end
