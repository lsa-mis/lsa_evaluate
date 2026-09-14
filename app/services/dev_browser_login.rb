# frozen_string_literal: true

# Local-only substitute for U-M SAML so tools like the Cursor IDE browser
# can sign in without the campus identity provider.
#
# Must never be available on staging or production. Even in development,
# requests must come from a loopback host.
class DevBrowserLogin
  ALLOWED_HOSTS = %w[localhost 127.0.0.1 ::1 [::1]].freeze

  class << self
    def allowed?(request)
      env_allowed? && host_allowed?(request) && local_request?(request)
    end

    def env_allowed?
      return false if Rails.env.staging? || Rails.env.production?

      Rails.env.development? || Rails.env.test?
    end

    def host_allowed?(request)
      ALLOWED_HOSTS.include?(request.host)
    end

    def local_request?(request)
      request.local?
    end
  end
end
