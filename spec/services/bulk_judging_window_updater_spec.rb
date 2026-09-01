# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkJudgingWindowUpdater do
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

  it 'updates the selected round end date' do
    result = described_class.new(
      round_ids: [round_one.id],
      end_date: '2026-03-14 17:00',
      cascade: false
    ).call

    expect(result.success?).to be true
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-14 17:00'))
  end

  it 'cascades following round dates when enabled' do
    result = described_class.new(
      round_ids: [round_one.id],
      end_date: '2026-03-22 17:00',
      cascade: true
    ).call

    expect(result.success?).to be true
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-22 17:00'))
    expect(round_two.reload.start_date).to eq(Time.zone.parse('2026-03-22 17:00'))
    expect(result.cascaded).not_to be_empty
  end

  it 'fails when cascade is disabled and dates conflict' do
    result = described_class.new(
      round_ids: [round_one.id],
      end_date: '2026-03-22 17:00',
      cascade: false
    ).call

    expect(result.success?).to be false
    expect(result.failed.first[:errors]).to be_present
  end
end
