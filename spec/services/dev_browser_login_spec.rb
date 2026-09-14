# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DevBrowserLogin do
  def request_double(host: 'localhost', local: true)
    instance_double(ActionDispatch::Request, host:, local?: local)
  end

  describe '.env_allowed?' do
    it 'is true in development' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

      expect(described_class.env_allowed?).to be true
    end

    it 'is true in test so the picker can be specced' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))

      expect(described_class.env_allowed?).to be true
    end

    it 'is false in staging' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('staging'))

      expect(described_class.env_allowed?).to be false
    end

    it 'is false in production' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

      expect(described_class.env_allowed?).to be false
    end
  end

  describe '.allowed?' do
    before { allow(described_class).to receive(:env_allowed?).and_return(true) }

    it 'allows loopback requests to localhost' do
      expect(described_class.allowed?(request_double)).to be true
    end

    it 'allows IPv6 loopback hosts used by some browsers' do
      expect(described_class.allowed?(request_double(host: '::1'))).to be true
      expect(described_class.allowed?(request_double(host: '[::1]'))).to be true
    end

    it 'rejects a non-local host even in development' do
      expect(described_class.allowed?(request_double(host: 'evaluate.lsa.umich.edu'))).to be false
    end

    it 'rejects a non-loopback client even when the host is localhost' do
      expect(described_class.allowed?(request_double(local: false))).to be false
    end

    it 'rejects every request when the environment is not allowed' do
      allow(described_class).to receive(:env_allowed?).and_return(false)

      expect(described_class.allowed?(request_double)).to be false
    end
  end
end
