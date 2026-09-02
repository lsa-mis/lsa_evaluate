# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgingRoundDateCascadePlanner do
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
    it 'returns no conflicts when the new end date does not overlap the next round' do
      plan = described_class.new(round_one, proposed_end_date: '2026-03-15 18:00').call

      expect(plan[:conflicts]).to be false
      expect(plan[:affected_rounds].size).to eq(1)
      expect(plan[:affected_rounds].first.field).to eq(:end_date)
    end

    it 'proposes bumping the next round start date on conflict' do
      plan = described_class.new(round_one, proposed_end_date: '2026-03-22 17:00').call

      expect(plan[:conflicts]).to be true
      start_change = plan[:affected_rounds].find { |change| change.round == round_two && change.field == :start_date }
      expect(start_change.to).to eq(Time.zone.parse('2026-03-22 17:00'))
    end

    it 'preserves the original gap between rounds when requested' do
      plan = described_class.new(
        round_one,
        proposed_end_date: '2026-03-22 17:00',
        mode: :preserve_gaps
      ).call

      start_change = plan[:affected_rounds].find { |change| change.round == round_two && change.field == :start_date }
      expect(start_change.to).to eq(Time.zone.parse('2026-03-23 09:00'))
    end

    it 'cascades through later rounds when the start bump invalidates the end date' do
      round_two.update!(start_date: Time.zone.parse('2026-03-16 09:00'), end_date: Time.zone.parse('2026-03-20 17:00'))
      round_three = create(:judging_round,
                           contest_instance: contest_instance,
                           round_number: 3,
                           start_date: Time.zone.parse('2026-03-21 09:00'),
                           end_date: Time.zone.parse('2026-04-05 17:00'))

      plan = described_class.new(round_one, proposed_end_date: '2026-03-25 17:00').call

      round_two_end_change = plan[:affected_rounds].find { |change| change.round == round_two && change.field == :end_date }
      round_three_start_change = plan[:affected_rounds].find { |change| change.round == round_three && change.field == :start_date }

      expect(round_two_end_change).to be_present
      expect(round_three_start_change).to be_present
    end
  end
end
