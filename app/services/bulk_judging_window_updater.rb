# frozen_string_literal: true

class BulkJudgingWindowUpdater
  Result = Struct.new(:updated, :failed, :cascaded, keyword_init: true) do
    def initialize(updated: [], failed: [], cascaded: [])
      super
    end

    def success?
      failed.empty?
    end
  end

  def initialize(round_ids:, end_date:, start_date: nil, update_start_date: false, cascade: true, cascade_mode: :minimum_bump)
    @round_ids = Array(round_ids).map(&:to_i).uniq
    @end_date = end_date
    @start_date = start_date
    @update_start_date = update_start_date
    @cascade = cascade
    @cascade_mode = cascade_mode
  end

  def call
    result = Result.new
    rounds_by_instance = load_rounds.group_by(&:contest_instance)

    rounds_by_instance.each do |_instance, selected_rounds|
      process_instance_rounds(selected_rounds, result)
    end

    result
  end

  private

  def load_rounds
    JudgingRound.where(id: @round_ids)
                .includes(contest_instance: { contest_description: :container, judging_rounds: [] })
                .order('contest_instances.id', 'judging_rounds.round_number')
  end

  def process_instance_rounds(selected_rounds, result)
    ActiveRecord::Base.transaction do
      selected_rounds.each do |round|
        apply_round_update(round, result)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    result.failed << failure_entry(round_from_error(e), e.record.errors.full_messages)
  rescue StandardError => e
    result.failed << failure_entry(selected_rounds.first, [e.message])
  end

  def apply_round_update(round, result)
    update_result = JudgingRoundDateUpdater.new(
      round,
      end_date: @end_date,
      start_date: @start_date,
      update_start_date: @update_start_date,
      cascade: @cascade,
      cascade_mode: @cascade_mode
    ).call

    unless update_result.success
      raise ActiveRecord::RecordInvalid.new(round.tap do |r|
        update_result.errors.each { |message| r.errors.add(:base, message) }
      end)
    end

    result.cascaded.concat(update_result.cascaded)
    result.updated << round
  end

  def failure_entry(round, errors)
    {
      round: round,
      contest_name: round.contest_instance.contest_description.name,
      round_number: round.round_number,
      errors: errors
    }
  end

  def round_from_error(error)
    error.record.is_a?(JudgingRound) ? error.record : JudgingRound.new
  end
end
