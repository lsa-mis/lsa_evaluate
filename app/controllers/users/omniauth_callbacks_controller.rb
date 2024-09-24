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
        set_flash_message(:notice, :success, kind: kind)
      end
    end

    def user_is_stale?
      user_signed_in? && current_user.last_sign_in_at < 15.minutes.ago
    end

    def auth
      auth_hash = request.env['omniauth.auth']
      raw_info_hash = auth_hash['extra']['raw_info'].attributes rescue {}
      session[:raw_info_hash] = raw_info_hash
      # Rails.logger.info("@@@####  Auth Hash raw_info_hash: #{raw_info_hash}")
      request.env['omniauth.auth']
    end

    def set_user
      @user = find_or_initialize_user
      session[:user_email] = @user.email if @user
    end

    def find_or_initialize_user
      auth
      if user_signed_in?
        current_user
      else
        email = user_params[:email]
        @user = User.find_or_initialize_by(email: email)
        @user.assign_attributes(user_params)

        if @user.save
          sync_affiliations(@user)
          @user
        else
          Rails.logger.error("Failed to create/update user: #{@user.errors.full_messages.join(', ')}")
          flash[:alert] = "User creation/update failed: #{@user.errors.full_messages.join(', ')}"
          redirect_to new_user_registration_path and return
        end
      end
    end

    def sync_affiliations(user)
      # Ensure user is present
      return unless user.present?

      # Extract new affiliations from session
      new_affiliations = session[:raw_info_hash]['urn:oid:1.3.6.1.4.1.5923.1.1.1.1']&.map { |value| value.to_s.downcase } || []
      Rails.logger.info("@@@@@@ New Affiliations: #{new_affiliations}")

      # Safely retrieve current affiliations
      current_affiliations = user.affiliations.pluck(:name).map { |name| name.to_s.downcase }
      Rails.logger.info("@@@@@@ Current Affiliations: #{current_affiliations}")

      ActiveRecord::Base.transaction do
        # Add new affiliations that are not already present
        (new_affiliations - current_affiliations).each do |affiliation_name|
          user.affiliations.create!(name: affiliation_name)
          Rails.logger.info("Added affiliation: #{affiliation_name}")
        end

        # Remove affiliations that are no longer present
        (current_affiliations - new_affiliations).each do |affiliation_name|
          affiliation = user.affiliations.find_by(name: affiliation_name)
          if affiliation
            affiliation.destroy!
            Rails.logger.info("Removed affiliation: #{affiliation_name}")
          else
            Rails.logger.warn("Affiliation not found for removal: #{affiliation_name}")
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to sync affiliations: #{e.message}")
      # Optionally, add further error handling here, such as notifying the user
      flash[:alert] = "Failed to sync affiliations: #{e.message}"
      redirect_to new_user_registration_path and return
    end

    def user_params
      {
        email: session[:raw_info_hash]['urn:oid:1.3.6.1.4.1.5923.1.1.1.6']&.first,
        uniqname: session[:raw_info_hash]['urn:oid:0.9.2342.19200300.100.1.1']&.first,
        uid: session[:raw_info_hash]['http://www.itcs.umich.edu/identity/shibboleth/attributes/cosignPrincipalName']&.first,
        principal_name: session[:raw_info_hash]['http://its.umich.edu/shibboleth/attributes/umichPrincipalName']&.first,
        display_name: session[:raw_info_hash]['urn:oid:2.16.840.1.113730.3.1.241']&.first,
        first_name: session[:raw_info_hash]['urn:oid:2.5.4.42']&.first,
        last_name: session[:raw_info_hash]['urn:oid:2.5.4.4']&.first,
        password: Devise.friendly_token[0, 20]
      }
    end
  end
end
