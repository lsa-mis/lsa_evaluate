# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkContestInstanceActivationForm do
  subject(:form) do
    described_class.new(date_open: date_open, confirmed: confirmed)
  end

  let(:date_open) { 1.month.from_now.iso8601 }
  let(:confirmed) { '1' }

  context 'when confirmed with a valid date' do
    it { is_expected.to be_valid }
  end

  context 'when not confirmed' do
    let(:confirmed) { '0' }

    it 'is invalid' do
      expect(form).not_to be_valid
      expect(form.errors[:confirmed]).to be_present
    end
  end

  context 'when date_open is malformed' do
    let(:date_open) { '2026-99-99' }

    it 'is invalid without raising' do
      expect { form.valid? }.not_to raise_error
      expect(form).not_to be_valid
      expect(form.errors[:date_open]).to include('is not a valid date')
      expect(form.parsed_date_open).to be_nil
    end
  end
end
