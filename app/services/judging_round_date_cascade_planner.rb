# frozen_string_literal: true

class JudgingRoundDateCascadePlanner
  MODES = %i[minimum_bump preserve_gaps].freeze

  Change = Struct.new(:round, :field, :from, :to, :reason, keyword_init: true)

  def initialize(round, proposed_end_date:, proposed_start_date: nil, mode: :minimum_bump)
    @round = round
    @proposed_end_date = parse_time(proposed_end_date)
    @proposed_start_date = parse_time(proposed_start_date)
    @mode = MODES.include?(mode.to_sym) ? mode.to_sym : :minimum_bump
  end

  def call
    changes = []
    changes << build_change(@round, :end_date, @round.end_date, @proposed_end_date, 'Updated end date')

    if @proposed_start_date.present?
      changes << build_change(@round, :start_date, @round.start_date, @proposed_start_date, 'Updated start date')
    end

    subsequent_changes = cascade_subsequent_rounds(changes)
    all_changes = changes + subsequent_changes

    {
      conflicts: subsequent_changes.any?,
      affected_rounds: all_changes
    }
  end

  private

  def cascade_subsequent_rounds(initial_changes)
    changes = []
    rounds = ordered_rounds
    round_index = rounds.index(@round)
    return changes if round_index.nil?

    simulated_dates = rounds.each_with_object({}) do |round, dates|
      dates[round.id] = {
        start_date: round.start_date,
        end_date: round.end_date
      }
    end

    apply_changes_to_simulation!(simulated_dates, initial_changes)

    rounds[(round_index + 1)..].to_a.each do |subsequent_round|
      previous_round = rounds[rounds.index(subsequent_round) - 1]
      previous_end = simulated_dates[previous_round.id][:end_date]
      current_start = simulated_dates[subsequent_round.id][:start_date]

      next unless previous_end && current_start && current_start < previous_end

      new_start = proposed_start_for(subsequent_round, previous_round, previous_end, simulated_dates)
      changes << build_change(
        subsequent_round,
        :start_date,
        subsequent_round.start_date,
        new_start,
        "Must be on or after Round #{previous_round.round_number} end date"
      )
      simulated_dates[subsequent_round.id][:start_date] = new_start

      current_end = simulated_dates[subsequent_round.id][:end_date]
      next unless current_end && current_end < new_start

      duration = subsequent_round.end_date - subsequent_round.start_date
      new_end = new_start + duration
      changes << build_change(
        subsequent_round,
        :end_date,
        subsequent_round.end_date,
        new_end,
        'End date shifted to remain after start date'
      )
      simulated_dates[subsequent_round.id][:end_date] = new_end
    end

    changes
  end

  def proposed_start_for(subsequent_round, previous_round, previous_end, simulated_dates)
    case @mode
    when :preserve_gaps
      original_gap = subsequent_round.start_date - previous_round.end_date
      previous_end + original_gap
    else
      previous_end
    end
  end

  def apply_changes_to_simulation!(simulated_dates, changes)
    changes.each do |change|
      simulated_dates[change.round.id][change.field] = change.to
    end
  end

  def ordered_rounds
    @round.contest_instance.judging_rounds.order(:round_number).to_a
  end

  def build_change(round, field, from, to, reason)
    Change.new(round: round, field: field, from: from, to: to, reason: reason)
  end

  def parse_time(value)
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  end
end
