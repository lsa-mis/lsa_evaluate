# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: :saml
    before_action :set_user
    attr_reader :user, :service

    def saml
      handle_auth 'SAML'
    end

    private

    def handle_auth(kind)
      if user_signed_in?
        flash[:notice] = "Your #{kind} account was connected."
        redirect_to edit_user_registration_path
      else
        sign_in_and_redirect @user, event: :authentication
        set_flash_message :notice, :success, kind:
      end
    end

    def user_is_stale?
      return unless user_signed_in?

      current_user.last_sign_in_at < 15.minutes.ago
    end

    def auth
      request.env['omniauth.auth']
    end

    def set_user
      @user = if user_signed_in?
                current_user
              elsif User.where(email: auth.info.email).any?
                User.find_by(email: auth.info.email)
              else
                create_user
              end

      return unless @user

      session[:user_email] = @user.email
    end

    def get_uniqname(email)
      email.split('@').first
    end

    def create_user
      @user = User.create(
        email: auth.info.email,
        uniqname: get_uniqname(auth.info.email),
        uid: auth.info.uid,
        principal_name: auth.info.principal_name,
        display_name: auth.info.name,
        person_affiliation: auth.info.person_affiliation,
        password: Devise.friendly_token[0, 20]
      )
    end
  end
end
