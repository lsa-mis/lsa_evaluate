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

  describe 'probe path blocking' do
    [
      '/xampp/php-cgi.exe',
      '/php-cgi/php-cgi.exe',
      '/home.cgi',
      '/start.shtml',
      '/login.aspx',
      '/main.cfm',
      '/menu.jsa',
      '/kubepi/fav.png',
      '/officescan/console/html/localization.js',
      '/administrator/manifests/files/joomla.xml',
      '/WebApp/js/UI_String.js',
      '/ext-js/app/common/zld_product_spec.js',
      '/css/eonweb.css',
      '/images/logo.gif',
      '/phoenix/favicon.ico',
      '/CHANGELOG.txt',
      '/plugins/editors/jce/jce.xml'
    ].each do |probe_path|
      it "blocks GET requests to #{probe_path}" do
        status, _headers, body = call_with(path: probe_path)

        expect(status).to eq(403)
        expect(body).to eq(['Forbidden'])
      end
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

    it 'blocks POST requests with uppercase PHP tags in the body' do
      status, = call_with(
        path: '/',
        method: 'POST',
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' },
        input: 'payload=<?PHP system($_GET["cmd"]); ?>'
      )

      expect(status).to eq(403)
    end

    it 'does not raise when rack.input is missing' do
      env = Rack::MockRequest.env_for('/', method: 'POST')
      env.delete('rack.input')

      expect { middleware.call(env) }.not_to raise_error
    end

    it 'preserves the POST body for downstream handlers' do
      captured_body = nil
      original_input = nil
      inspecting_app = lambda do |env|
        captured_body = env['rack.input'].read
        [200, {}, ['OK']]
      end

      env = Rack::MockRequest.env_for(
        '/entries',
        method: 'POST',
        input: 'name=test&value=1',
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )
      original_input = env['rack.input']

      status, = described_class.new(inspecting_app).call(env)

      expect(status).to eq(200)
      expect(captured_body).to eq('name=test&value=1')
      expect(env['rack.input']).to equal(original_input)
    end

    it 'does not desync Rack POST cache from rack.input' do
      inspecting_app = ->(_env) { [200, {}, ['OK']] }
      env = Rack::MockRequest.env_for(
        '/entries',
        method: 'POST',
        input: 'name=test&value=1',
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )

      status, = described_class.new(inspecting_app).call(env)

      expect(status).to eq(200)
      request = Rack::Request.new(env)
      expect(request.POST).to eq('name' => 'test', 'value' => '1')
      expect(env[Rack::RACK_REQUEST_FORM_INPUT]).to equal(env['rack.input'])
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
