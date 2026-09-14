# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatabaseAuthentication do
  describe '.enabled?' do
    it 'allows password authentication in development and test' do
      expect(described_class.enabled?(env: 'development')).to be(true)
      expect(described_class.enabled?(env: 'test')).to be(true)
    end

    it 'disables password authentication in staging and production' do
      expect(described_class.enabled?(env: 'staging')).to be(false)
      expect(described_class.enabled?(env: 'production')).to be(false)
    end
  end
end
