# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rack::Defense do
  subject(:middleware) { described_class.new(app) }

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

  def call_with(path:, method: 'GET', headers: {}, input: nil)
    env = Rack::MockRequest.env_for(path, method: method, input: input)
    headers.each { |key, value| env[key] = value }
    middleware.call(env)
  end

  describe 'PHP / probe path blocking' do
    it 'blocks GET requests to php-cgi probe paths' do
      status, _headers, body = call_with(path: '/xampp/php-cgi.exe')

      expect(status).to eq(403)
      expect(body).to eq(['Forbidden'])
    end

    it 'blocks GET requests to /php-cgi/php-cgi.exe' do
      status, = call_with(path: '/php-cgi/php-cgi.exe')

      expect(status).to eq(403)
    end

    it 'blocks POST requests with php content in the body' do
      status, = call_with(
        path: '/',
        method: 'POST',
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' },
        input: 'payload=<?php system($_GET["cmd"]); ?>'
      )

      expect(status).to eq(403)
    end
  end

  describe 'invalid UTF-8 handling' do
    it 'does not raise when env strings contain invalid UTF-8 bytes' do
      expect do
        call_with(
          path: '/',
          headers: { 'HTTP_USER_AGENT' => "scanner\xFF\xFE".b }
        )
      end.not_to raise_error
    end

    it 'sanitizes invalid UTF-8 before passing the request downstream' do
      captured_env = nil
      inspecting_app = lambda do |env|
        captured_env = env
        [200, {}, ['OK']]
      end
      middleware = described_class.new(inspecting_app)

      env = Rack::MockRequest.env_for('/')
      env['HTTP_USER_AGENT'] = "scanner\xFF\xFE".b
      status, = middleware.call(env)

      expect(status).to eq(200)
      expect(captured_env['HTTP_USER_AGENT']).to be_valid_encoding
      expect(captured_env['HTTP_USER_AGENT']).not_to include("\xFF".b)
    end

    it 'returns 400 when an invalid byte sequence ArgumentError escapes sanitization' do
      exploding_app = lambda do |_env|
        raise ArgumentError, 'invalid byte sequence in UTF-8'
      end
      middleware = described_class.new(exploding_app)

      status, _headers, body = middleware.call(Rack::MockRequest.env_for('/'))

      expect(status).to eq(400)
      expect(body).to eq(['Bad Request'])
    end
  end

  describe 'normal requests' do
    it 'allows a normal GET request through to the app' do
      status, _headers, body = call_with(path: '/')

      expect(status).to eq(200)
      expect(body).to eq(['OK'])
    end
  end
end
