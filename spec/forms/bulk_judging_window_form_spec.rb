# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkJudgingWindowForm do
  describe 'validations' do
    it 'requires an end date' do
      form = described_class.new(end_date: nil)

      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include("can't be blank")
    end

    it 'rejects an end date before the start date when updating start date' do
      form = described_class.new(
        end_date: '2026-03-10 17:00',
        start_date: '2026-03-12 09:00',
        update_start_date: '1'
      )

      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include('must be after start date')
    end

    it 'rejects unparseable end dates' do
      form = described_class.new(end_date: 'not-a-date')

      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include('is not a valid date')
    end

    it 'rejects end dates with an unreasonable year' do
      form = described_class.new(end_date: '2101-01-01 00:00')

      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include('is not a valid date')
    end

    it 'rejects unparseable start dates when updating start date' do
      form = described_class.new(
        end_date: '2026-03-20 17:00',
        start_date: 'not-a-date',
        update_start_date: '1'
      )

      expect(form).not_to be_valid
      expect(form.errors[:start_date]).to include('is not a valid date')
    end

    it 'is valid with a parseable end date' do
      form = described_class.new(end_date: '2026-03-20 17:00')

      expect(form).to be_valid
    end
  end

  describe 'boolean and mode helpers' do
    it 'casts cascade and update_start_date flags' do
      form = described_class.new(
        cascade_following_rounds: '1',
        update_start_date: '0'
      )

      expect(form.cascade_enabled?).to be true
      expect(form.update_start_date?).to be false
    end

    it 'defaults cascade_mode to minimum_bump' do
      form = described_class.new(cascade_mode: nil)

      expect(form.cascade_mode_symbol).to eq(:minimum_bump)
    end

    it 'parses start and end dates in the application time zone' do
      form = described_class.new(
        end_date: '2026-03-20 17:00',
        start_date: '2026-03-10 09:00'
      )

      expect(form.parsed_end_date).to eq(Time.zone.parse('2026-03-20 17:00'))
      expect(form.parsed_start_date).to eq(Time.zone.parse('2026-03-10 09:00'))
    end
  end
end
