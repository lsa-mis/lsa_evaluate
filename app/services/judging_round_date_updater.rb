# frozen_string_literal: true

class JudgingRoundDateUpdater
  Result = Struct.new(:success, :errors, :cascaded, keyword_init: true) do
    def initialize(success: false, errors: [], cascaded: [])
      super
    end
  end

  def initialize(round, end_date:, start_date: nil, update_start_date: false, cascade: true, cascade_mode: :minimum_bump)
    @round = round
    @end_date = end_date
    @start_date = start_date
    @update_start_date = update_start_date
    @cascade = cascade
    @cascade_mode = cascade_mode
  end

  def call
    plan = JudgingRoundDateCascadePlanner.new(
      @round,
      proposed_end_date: @end_date,
      proposed_start_date: @update_start_date ? @start_date : nil,
      mode: @cascade_mode
    ).call

    if plan[:conflicts] && !@cascade
      return Result.new(
        success: false,
        errors: ['Extending this round conflicts with following round dates. Enable cascade to adjust them.']
      )
    end

    cascaded = []
    ActiveRecord::Base.transaction do
      # Apply all field changes for a round in one update so validations
      # see the full intended state (e.g. fixing start_date while also
      # changing end_date). Field-by-field updates re-validate against
      # stale attributes and can falsely fail.
      changes_by_round = plan[:affected_rounds].group_by(&:round)
      changes_by_round.each do |round, changes|
        attributes = changes.to_h { |change| [ change.field, change.to ] }
        round.update!(attributes)
        cascaded.concat(changes) if round.id != @round.id
      end
    end

    Result.new(success: true, cascaded: cascaded)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, errors: e.record.errors.full_messages)
  end
end
