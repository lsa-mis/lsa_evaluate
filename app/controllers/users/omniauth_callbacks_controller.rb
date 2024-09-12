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
      # Rails.logger.info("@@@@@@  Omniauth Auth Hash: #{request.env['omniauth.auth'].inspect}")
      auth_hash = request.env['omniauth.auth']
      urn_values = auth_hash['extra']['raw_info'].attributes['urn:oid:1.3.6.1.4.1.5923.1.1.1.1'] rescue []
      urn_values = Array(urn_values)

      Rails.logger.info("@@@@@@  URN Values: #{urn_values.join(', ')}")

      session[:urn_values] = urn_values
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
        update_user(user)
      else
        create_user
      end
    end

    def get_uniqname(email)
      email.split('@').first
    end

    def create_user
      User.create(user_params)
      sync_affiliations(user)
      user
    end

    def update_user(user)
      user.update(user_params)
      sync_affiliations(user)
      user
    end

    def sync_affiliations(user)
      new_affiliations = session[:urn_values].map { |value| value.downcase }
      current_affiliations = user.affiliations.pluck(:name).map(&:downcase)

      # Add new affiliations
      (new_affiliations - current_affiliations).each do |affiliation_name|
        user.affiliations.create(name: affiliation_name)
      end

      # Remove old affiliations
      (current_affiliations - new_affiliations).each do |affiliation_name|
        user.affiliations.find_by(name: affiliation_name).destroy
      end
    end

    def user_params
      {
        email: auth.info.email,
        uniqname: get_uniqname(auth.info.email),
        uid: auth.info.uid,
        principal_name: auth.info.principal_name,
        display_name: auth.info.name,
        password: Devise.friendly_token[0, 20]
      }
    end
  end
end
