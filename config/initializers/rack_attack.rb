# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Spammy Clients ###
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params['email'].to_s.downcase.gsub(/\s+/, '')
    end
  end

  # Block suspicious requests for PHP files or with PHP-related payload
  blocklist('block-suspicious-requests') do |req|
    php_patterns = [
      /\.php$/i,
      /php/i,
      /eval\(/i,
      /system\(/i,
      /exec\(/i,
      /\<\?php/i
    ]

    # Check path and parameters for PHP patterns
    path_suspicious = php_patterns.any? { |pattern| req.path =~ pattern }
    params_suspicious = req.params.values.any? do |value|
      php_patterns.any? { |pattern| value.to_s =~ pattern }
    end

    path_suspicious || params_suspicious
  end

  # Block known malicious IP addresses
  blocklist('block-known-attackers') do |req|
    known_attackers = [
      '58.211.18.68'  # Add the malicious IP you've identified
    ]
    known_attackers.include?(req.ip)
  end

  ### Custom Throttle Response ###
  self.throttled_response = lambda do |env|
    now = Time.now
    match_data = env['rack.attack.match_data']

    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
    }

    [ 429, headers, [{ error: "Rate limit exceeded. Please try again later." }.to_json]]
  end

  ### Custom Blocklist Response ###
  self.blocklisted_response = lambda do |env|
    # Log the blocked request
    Rails.logger.warn(
      "[Security] Blocked suspicious request from IP: #{env['rack.attack.match_data'][:request].ip}, " \
      "Path: #{env['rack.attack.match_data'][:request].path}"
    )

    # Send to Sentry
    Sentry.capture_message(
      "Blocked suspicious request",
      level: 'warning',
      extra: {
        ip: env['rack.attack.match_data'][:request].ip,
        path: env['rack.attack.match_data'][:request].path,
        user_agent: env['rack.attack.match_data'][:request].user_agent
      }
    )

    [
      403,
      {'Content-Type' => 'application/json'},
      [{ error: 'Forbidden' }.to_json]
    ]
  end
end
