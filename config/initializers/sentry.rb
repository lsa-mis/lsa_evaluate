# frozen_string_literal: true

require_relative '../../lib/sentry_release'

Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)

  # Only enable in production and staging environments
  config.enabled_environments = %w[production staging]

  config.environment = Rails.env
  config.release = SentryRelease.current
  config.server_name = Socket.gethostname

  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Keep PII off by default; user id/email are set explicitly in ApplicationController
  config.send_default_pii = false

  # Capture all errors — sample only performance data (high-traffic apps still need full error coverage)
  config.sample_rate = 1.0

  config.max_breadcrumbs = 50

  # Dynamic trace sampling (takes precedence over traces_sample_rate)
  # sentry-rails already excludes RoutingError / UnknownFormat / etc. from error reporting
  config.traces_sampler = lambda do |context|
    transaction_name = context.dig(:transaction_context, :name).to_s

    return 0.0 if transaction_name.include?('health_check')
    return 0.0 if transaction_name.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?)$/i)

    # Respect parent sampling decision for distributed traces (browser → Rails)
    return context[:parent_sampled] unless context[:parent_sampled].nil?

    Rails.env.production? ? 0.1 : 1.0
  end

  # Relative to sampled traces; requires the stackprof gem (already in Gemfile)
  config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0

  config.before_send = lambda do |event, _hint|
    event.tags = (event.tags || {}).merge(
      environment: Rails.env,
      app: 'lsa-evaluate'
    )

    event
  end

  config.before_send_transaction = lambda do |event, _hint|
    return nil if event.transaction&.include?('health_check')
    return nil if event.transaction&.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?)$/i)

    event
  end

  config.before_breadcrumb = lambda do |breadcrumb, _hint|
    return nil if breadcrumb.message&.match?(/password|token|secret/i)
    return nil if breadcrumb.message&.match?(/SELECT.*FROM.*users/i)

    breadcrumb
  end

  config.backtrace_cleanup_callback = lambda do |backtrace|
    Rails.backtrace_cleaner.clean(backtrace)
  end

  # Useful on staging when diagnosing SDK issues (Sentry is disabled in development)
  config.debug = Rails.env.staging?
end
