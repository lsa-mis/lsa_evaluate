# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile do
  let(:user) { create(:user) }
  let(:class_level) { create(:class_level) }

  let(:profile) do
    described_class.new(
      user:,
      legal_first_name: 'Legal',
      legal_last_name: 'Name',
      preferred_first_name: 'Preferred',
      preferred_last_name: 'Person',
      umid: format('%08d', rand(10_000_000..99_999_999)),
      class_level:
    )
  end

  describe 'validations' do
    it 'is valid with minimal identity attributes' do
      expect(profile).to be_valid
    end

    it 'requires legal names' do
      profile.legal_first_name = nil
      profile.legal_last_name = nil
      expect(profile).not_to be_valid
    end

    it 'allows blank preferred names' do
      profile.preferred_first_name = nil
      profile.preferred_last_name = nil
      expect(profile).to be_valid
    end

    it 'does not require degree, campus, school, or grad_date' do
      profile.degree = nil
      profile.grad_date = nil
      profile.campus = nil
      profile.school = nil
      expect(profile).to be_valid
    end

    it 'requires umid and class_level' do
      profile.umid = nil
      profile.class_level = nil
      expect(profile).not_to be_valid
    end
  end

  describe '#display_name' do
    it 'uses preferred name when present' do
      expect(profile.display_name).to eq('Preferred Person')
    end

    it 'falls back to legal name' do
      profile.preferred_first_name = nil
      profile.preferred_last_name = nil
      expect(profile.display_name).to eq('Legal Name')
    end

    it 'falls back to email' do
      profile.preferred_first_name = nil
      profile.preferred_last_name = nil
      profile.legal_first_name = ''
      profile.legal_last_name = ''
      allow(profile).to receive(:valid?).and_return(true)
      expect(profile.display_name).to eq(user.email)
    end
  end
end
