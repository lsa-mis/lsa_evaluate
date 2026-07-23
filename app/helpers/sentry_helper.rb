# frozen_string_literal: true

module SentryHelper
  def sentry_meta_tags
    dsn = Rails.application.credentials.dig(:sentry, :dsn)
    return if dsn.blank?
    return unless Sentry.configuration.enabled_environments.include?(Rails.env)

    safe_join(
      [
        tag.meta(name: 'sentry-dsn', content: dsn),
        tag.meta(name: 'sentry-environment', content: Rails.env),
        tag.meta(name: 'sentry-release', content: SentryRelease.current.to_s)
      ]
    )
  end

  def set_sentry_user(user)
    Sentry.set_user(id: user.id, email: user.email)
  end

  def set_sentry_context(key, value)
    Sentry.set_context(key, value)
  end
end
