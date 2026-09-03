# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgingRoundDateUpdater do
  let(:contest_instance) do
    create(:contest_instance,
           date_open: Time.zone.parse('2026-02-01 09:00'),
           date_closed: Time.zone.parse('2026-03-01 17:00'))
  end
  let!(:round_one) do
    create(:judging_round,
           contest_instance: contest_instance,
           round_number: 1,
           start_date: Time.zone.parse('2026-03-02 09:00'),
           end_date: Time.zone.parse('2026-03-15 17:00'))
  end
  let!(:round_two) do
    create(:judging_round,
           contest_instance: contest_instance,
           round_number: 2,
           start_date: Time.zone.parse('2026-03-16 09:00'),
           end_date: Time.zone.parse('2026-03-30 17:00'))
  end

  describe '#call' do
    it 'updates the round end date without cascading when there is no conflict' do
      result = described_class.new(
        round_one,
        end_date: '2026-03-14 17:00',
        cascade: false
      ).call

      expect(result.success).to be true
      expect(result.cascaded).to be_empty
      expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-14 17:00'))
      expect(round_two.reload.start_date).to eq(Time.zone.parse('2026-03-16 09:00'))
    end

    it 'updates start and end dates when update_start_date is enabled' do
      result = described_class.new(
        round_one,
        end_date: '2026-03-14 17:00',
        start_date: '2026-03-03 09:00',
        update_start_date: true,
        cascade: false
      ).call

      expect(result.success).to be true
      expect(round_one.reload.start_date).to eq(Time.zone.parse('2026-03-03 09:00'))
      expect(round_one.end_date).to eq(Time.zone.parse('2026-03-14 17:00'))
    end

    it 'cascades following round dates when cascade is enabled' do
      result = described_class.new(
        round_one,
        end_date: '2026-03-22 17:00',
        cascade: true
      ).call

      expect(result.success).to be true
      expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-22 17:00'))
      expect(round_two.reload.start_date).to eq(Time.zone.parse('2026-03-22 17:00'))
      expect(result.cascaded.map(&:round)).to include(round_two)
    end

    it 'fails without mutating dates when cascade is disabled and dates conflict' do
      original_round_one_end = round_one.end_date
      original_round_two_start = round_two.start_date

      result = described_class.new(
        round_one,
        end_date: '2026-03-22 17:00',
        cascade: false
      ).call

      expect(result.success).to be false
      expect(result.errors.join).to match(/cascade/i)
      expect(round_one.reload.end_date).to eq(original_round_one_end)
      expect(round_two.reload.start_date).to eq(original_round_two_start)
    end

    it 'returns validation errors when an update is invalid' do
      allow_any_instance_of(JudgingRound).to receive(:update!).and_raise(
        ActiveRecord::RecordInvalid.new(round_one.tap { |r| r.errors.add(:end_date, 'is invalid') })
      )

      result = described_class.new(
        round_one,
        end_date: '2026-03-14 17:00',
        cascade: false
      ).call

      expect(result.success).to be false
      expect(result.errors).to include('End date is invalid')
    end
  end
end
