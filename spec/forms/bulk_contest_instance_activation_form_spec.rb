# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkContestInstanceActivationForm do
  subject(:form) do
    described_class.new(date_open: 1.month.from_now.iso8601, confirmed: confirmed)
  end

  context 'when confirmed' do
    let(:confirmed) { '1' }

    it { is_expected.to be_valid }
  end

  context 'when not confirmed' do
    let(:confirmed) { '0' }

    it 'is invalid' do
      expect(form).not_to be_valid
      expect(form.errors[:confirmed]).to be_present
    end
  end
end
