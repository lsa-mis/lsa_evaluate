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

  it 'returns success with no updates when round_ids are empty' do
    result = described_class.new(
      round_ids: [],
      end_date: '2026-03-14 17:00',
      cascade: false
    ).call

    expect(result.success?).to be true
    expect(result.updated).to be_empty
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-15 17:00'))
  end

  it 'ignores unknown round ids and deduplicates selected ids' do
    result = described_class.new(
      round_ids: [round_one.id, round_one.id, 0],
      end_date: '2026-03-14 17:00',
      cascade: false
    ).call

    expect(result.success?).to be true
    expect(result.updated.map(&:id)).to eq([round_one.id])
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-14 17:00'))
  end

  it 'updates the selected round start date when requested' do
    result = described_class.new(
      round_ids: [round_two.id],
      end_date: '2026-03-30 17:00',
      start_date: '2026-03-17 09:00',
      update_start_date: true,
      cascade: false
    ).call

    expect(result.success?).to be true
    expect(round_two.reload.start_date).to eq(Time.zone.parse('2026-03-17 09:00'))
    expect(round_two.end_date).to eq(Time.zone.parse('2026-03-30 17:00'))
  end

  it 'preserves gaps between rounds when cascading in preserve_gaps mode' do
    result = described_class.new(
      round_ids: [round_one.id],
      end_date: '2026-03-22 17:00',
      cascade: true,
      cascade_mode: :preserve_gaps
    ).call

    expect(result.success?).to be true
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-22 17:00'))
    # Original gap between round 1 end (03-15 17:00) and round 2 start (03-16 09:00) is 16 hours.
    expect(round_two.reload.start_date).to eq(Time.zone.parse('2026-03-23 09:00'))
  end

  it 'updates rounds across multiple contest instances in one call' do
    other_instance = create(
      :contest_instance,
      contest_description: contest_instance.contest_description,
      active: false,
      date_open: Time.zone.parse('2026-02-01 09:00'),
      date_closed: Time.zone.parse('2026-03-01 17:00')
    )
    other_round = create(
      :judging_round,
      contest_instance: other_instance,
      round_number: 1,
      start_date: Time.zone.parse('2026-03-02 09:00'),
      end_date: Time.zone.parse('2026-03-15 17:00')
    )

    result = described_class.new(
      round_ids: [round_one.id, other_round.id],
      end_date: '2026-03-14 12:00',
      cascade: false
    ).call

    expect(result.success?).to be true
    expect(result.updated.map(&:id)).to contain_exactly(round_one.id, other_round.id)
    expect(round_one.reload.end_date).to eq(Time.zone.parse('2026-03-14 12:00'))
    expect(other_round.reload.end_date).to eq(Time.zone.parse('2026-03-14 12:00'))
  end
end
