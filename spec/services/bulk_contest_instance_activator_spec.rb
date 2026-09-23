# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkContestInstanceActivator do
  let(:department) { create(:department) }
  let(:container) { create(:container, department: department) }
  let(:season_open) { 1.month.from_now.change(usec: 0) }

  def create_active_instance(description, attrs = {})
    create(
      :contest_instance,
      {
        contest_description: description,
        active: true,
        date_open: 2.months.ago,
        date_closed: 1.month.ago
      }.merge(attrs)
    )
  end

  def create_season_instance(description, attrs = {})
    create(
      :contest_instance,
      {
        contest_description: description,
        active: false,
        date_open: season_open,
        date_closed: season_open + 1.month
      }.merge(attrs)
    )
  end

  describe '.available_seasons_for' do
    it 'groups inactive instances by shared date_open even when close dates differ' do
      description_one = create(:contest_description, :active, container: container)
      description_two = create(:contest_description, :active, container: container)
      create_season_instance(description_one, date_closed: season_open + 2.weeks)
      create_season_instance(description_two, date_closed: season_open + 6.weeks)

      seasons = described_class.available_seasons_for(container)

      expect(seasons.size).to eq(1)
      expect(seasons.first.date_open).to eq(season_open)
      expect(seasons.first.description_count).to eq(2)
      expect(seasons.first.earliest_close).to eq(season_open + 2.weeks)
      expect(seasons.first.latest_close).to eq(season_open + 6.weeks)
    end

    it 'excludes archived instances' do
      description = create(:contest_description, :active, container: container)
      create_season_instance(description, archived: true)

      expect(described_class.available_seasons_for(container)).to be_empty
    end
  end

  describe '#call' do
    let(:description) { create(:contest_description, :active, container: container) }
    let!(:predecessor) { create_active_instance(description) }
    let!(:newest) { create_season_instance(description) }

    it 'activates the newest instance and deactivates the predecessor' do
      result = described_class.new(container: container, date_open: season_open).call

      expect(result.failed).to be_empty
      expect(newest.reload).to be_active
      expect(predecessor.reload).not_to be_active
      expect(description.contest_instances.where(active: true).count).to eq(1)
      expect(description.contest_instances.find_by(active: true)).to eq(newest)
    end

    it 'completes incomplete judging rounds on the predecessor' do
      round_one = create(
        :judging_round,
        contest_instance: predecessor,
        round_number: 1,
        active: true,
        completed: false,
        start_date: predecessor.date_closed + 1.day,
        end_date: predecessor.date_closed + 2.days
      )
      round_two = create(
        :judging_round,
        contest_instance: predecessor,
        round_number: 2,
        active: false,
        completed: false,
        start_date: round_one.end_date + 1.day,
        end_date: round_one.end_date + 2.days
      )

      result = described_class.new(container: container, date_open: season_open).call

      expect(result.failed).to be_empty
      expect(round_one.reload).to be_completed
      expect(round_one).not_to be_active
      expect(round_two.reload).to be_completed
      expect(result.rounds_completed.size).to eq(2)
    end

    it 'skips inactive contest descriptions' do
      inactive_description = create(:contest_description, container: container, active: false)
      create_season_instance(inactive_description)

      result = described_class.new(container: container, date_open: season_open).call

      skipped = result.skipped.find { |entry| entry[:contest_description] == inactive_description }
      expect(skipped[:reason]).to eq('Contest description is inactive')
      expect(inactive_description.contest_instances.where(active: true)).to be_empty
    end

    it 'records unchanged when the newest instance is already active' do
      predecessor.update!(active: false)
      newest.update!(active: true)

      result = described_class.new(container: container, date_open: season_open).call

      expect(result.unchanged.map { |entry| entry[:contest_instance] }).to include(newest)
      expect(result.activated).to be_empty
    end

    it 'activates future-dated instances' do
      future_open = 3.months.from_now.change(usec: 0)
      newest.update!(date_open: future_open, date_closed: future_open + 1.month)

      result = described_class.new(container: container, date_open: future_open).call

      expect(result.failed).to be_empty
      expect(newest.reload).to be_active
      expect(predecessor.reload).not_to be_active
    end

    it 'continues processing other descriptions when one fails' do
      other_description = create(:contest_description, :active, container: container)
      other_predecessor = create_active_instance(other_description)
      other_newest = create_season_instance(other_description)

      allow_any_instance_of(ContestInstance).to receive(:update!).and_wrap_original do |method, *args|
        if method.receiver.id == newest.id && args.first[:active] == true
          raise ActiveRecord::RecordInvalid.new(newest)
        end
        method.call(*args)
      end

      result = described_class.new(container: container, date_open: season_open).call

      expect(result.failed.map { |entry| entry[:contest_description] }).to include(description)
      expect(other_newest.reload).to be_active
      expect(other_predecessor.reload).not_to be_active
    end

    it 'never leaves two active instances for one description' do
      described_class.new(container: container, date_open: season_open).call

      expect(description.contest_instances.where(active: true).pluck(:id)).to eq([newest.id])
    end
  end
end
