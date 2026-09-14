# frozen_string_literal: true

# Password (database) login is for local development and tests only.
# Staging and production must use U-M SAML.
class DatabaseAuthentication
  def self.enabled?(env: Rails.env)
    env.to_s.in?(%w[development test])
  end
end
