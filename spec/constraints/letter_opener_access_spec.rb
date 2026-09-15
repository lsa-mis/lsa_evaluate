# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetterOpenerAccess do
  let(:axis_mundi) { instance_double(User, axis_mundi?: true) }
  let(:judge) { instance_double(User, axis_mundi?: false) }

  describe '.allowed?' do
    it 'allows access in development regardless of user' do
      expect(described_class.allowed?(nil, env: 'development')).to be(true)
      expect(described_class.allowed?(judge, env: 'development')).to be(true)
    end

    it 'allows only axis mundi users in staging' do
      expect(described_class.allowed?(axis_mundi, env: 'staging')).to be(true)
      expect(described_class.allowed?(judge, env: 'staging')).to be(false)
      expect(described_class.allowed?(nil, env: 'staging')).to be(false)
    end

    it 'denies access in production and test' do
      expect(described_class.allowed?(axis_mundi, env: 'production')).to be(false)
      expect(described_class.allowed?(axis_mundi, env: 'test')).to be(false)
    end
  end
end
