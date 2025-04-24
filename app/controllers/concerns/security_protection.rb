# frozen_string_literal: true

module SecurityProtection
  extend ActiveSupport::Concern

  included do
    before_action :check_request_security
  end

  private

  def check_request_security
    # Check for invalid UTF-8 sequences
    unless valid_utf8_request?
      Rails.logger.warn("[Security] Invalid UTF-8 sequence detected from IP: #{request.remote_ip}")
      Sentry.capture_message("Invalid UTF-8 sequence detected",
        level: 'warning',
        extra: {
          ip: request.remote_ip,
          path: request.path,
          user_agent: request.user_agent
        }
      )
      return render_404
    end

    # Check for PHP-style attacks
    if php_attack_attempt?
      Rails.logger.warn("[Security] PHP probe attempt detected from IP: #{request.remote_ip}")
      Sentry.capture_message("PHP probe attempt detected",
        level: 'warning',
        extra: {
          ip: request.remote_ip,
          path: request.path,
          user_agent: request.user_agent,
          params: request.params.to_unsafe_h
        }
      )
      return render_403
    end
  end

  def valid_utf8_request?
    # Validate path
    path = request.path.dup
    path.force_encoding('UTF-8')
    return false unless path.valid_encoding?

    # Validate query parameters
    request.query_parameters.each do |key, value|
      next if value.nil?
      str = value.to_s.dup
      str.force_encoding('UTF-8')
      return false unless str.valid_encoding?
    end

    true
  end

  def php_attack_attempt?
    # Check for common PHP attack patterns
    path = request.path.downcase
    return true if path.end_with?('.php')
    return true if path.include?('php')
    return true if request.params.to_unsafe_h.values.any? { |v| v.to_s.include?('<?php') }

    # Check for common PHP vulnerability probe patterns
    suspicious_patterns = [
      'eval(', 'system(', 'exec(',
      'phpinfo', 'base64_decode',
      '.php', '<?php'
    ]

    suspicious_patterns.any? do |pattern|
      request.params.to_unsafe_h.values.any? { |v| v.to_s.downcase.include?(pattern) }
    end
  end

  def render_404
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
      format.any { head :not_found }
    end
  end

  def render_403
    respond_to do |format|
      format.html { render 'errors/forbidden', status: :forbidden }
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
      format.any { head :forbidden }
    end
  end
end
