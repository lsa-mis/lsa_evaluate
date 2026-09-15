# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remote IP header handling', type: :request do
  # Scanners send Client-IP: 127.0.0.1 while Hatchbox nginx sets X-Forwarded-For
  # to the real client. Rails RemoteIp raises IpSpoofAttackError on that mismatch
  # unless Client-IP is stripped (see Rack::Defense).
  it 'does not raise when Client-IP conflicts with X-Forwarded-For' do
    expect {
      get '/missing-page', headers: {
        'Client-IP' => '127.0.0.1',
        'X-Forwarded-For' => '203.0.113.50',
        'Forwarded' => 'for=203.0.113.50'
      }
    }.not_to raise_error

    expect(response).to have_http_status(:not_found)
  end

  it 'uses X-Forwarded-For as remote_ip after dropping Client-IP' do
    get '/missing-page', headers: {
      'Client-IP' => '127.0.0.1',
      'X-Forwarded-For' => '203.0.113.50'
    }

    expect(request.remote_ip).to eq('203.0.113.50')
  end
end
