module SentryHelper
  def set_sentry_user(user)
    Sentry.set_user(id: user.id, email: user.email)
  end

  def set_sentry_context(key, value)
    Sentry.set_context(key, value)
  end
end
