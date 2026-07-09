# frozen_string_literal: true

module Rack
  # Early-request filter for automated vulnerability scans and exploit probes.
  # This Rails app does not serve PHP, ASP, CGI, or other foreign stack assets.
  class Defense
    # File extensions used by scanners probing non-Rails stacks.
    PROBE_EXTENSIONS = %w[
      .php .exe .cgi .shtml .aspx .cfm .jsa .jsp .asp .pl
      .asmx .ashx .dll .bat .config
    ].freeze

    # Substrings matched against the request path or query string.
    PROBE_PATH_PATTERNS = [
      'php-cgi', 'xampp', 'wp-admin', 'wp-login',
      'officescan', 'kubepi', 'administrator/manifests',
      'ext-js', 'WebApp/', 'eonweb', 'phoenix/favicon',
      '/CHANGELOG.txt', '/images/logo',
      '/plugins/editors/jce/jce.xml'
    ].freeze

    SUSPICIOUS_HEADER_CHECKS = [
      ->(env) { env['HTTP_USER_AGENT'].to_s.include?('Custom-AsyncHttpClient') },
      ->(env) { env['HTTP_X_REQUEST_ID'].to_s.include?('cve_2024_4577') }
    ].freeze

    SUSPICIOUS_IPS = ['91.99.22.81'].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      sanitize_env!(env)

      request = Rack::Request.new(env)

      return forbidden if probe_path_request?(request)
      return forbidden if probe_post_body?(request)
      return forbidden if SUSPICIOUS_HEADER_CHECKS.any? { |check| check.call(env) }
      return forbidden if SUSPICIOUS_IPS.include?(request.ip)

      @app.call(env)
    rescue ArgumentError => e
      raise unless e.message.include?('invalid byte sequence')

      [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
    end

    private

    def sanitize_env!(env)
      env.each do |key, value|
        next unless value.is_a?(String)

        env[key] = value.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      end
    end

    def probe_path_request?(request)
      probe_path?(request.path.downcase, request.query_string.downcase)
    end

    def probe_path?(path, query)
      PROBE_EXTENSIONS.any? { |ext| path.include?(ext) || query.include?(ext) } ||
        PROBE_PATH_PATTERNS.any? { |pattern| path.include?(pattern.downcase) || query.include?(pattern.downcase) }
    end

    def probe_post_body?(request)
      return false unless request.post?

      return true if request.content_type.to_s.downcase.include?('php')

      body = request.body
      return false unless body.respond_to?(:read)

      content = body.read
      body.rewind if body.respond_to?(:rewind)
      content.downcase.include?('php')
    end

    def forbidden
      [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end
  end
end
