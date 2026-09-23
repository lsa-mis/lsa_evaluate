# frozen_string_literal: true

class BulkContestInstanceActivator
  Result = Struct.new(
    :activated,
    :deactivated,
    :rounds_completed,
    :skipped,
    :failed,
    :unchanged,
    keyword_init: true
  ) do
    def initialize(activated: [], deactivated: [], rounds_completed: [], skipped: [], failed: [], unchanged: [])
      super
    end

    def success?
      failed.empty?
    end
  end

  Season = Struct.new(:date_open, :description_count, :earliest_close, :latest_close, keyword_init: true)

  def initialize(container:, date_open:)
    @container = container
    @date_open = normalize_date_open(date_open)
  end

  def call
    result = Result.new

    description_ids.each do |description_id|
      process_description(description_id, result)
    end

    result
  end

  def self.available_seasons_for(container)
    ContestInstance.for_container(container)
                   .inactive
                   .not_archived
                   .group(:date_open)
                   .order(date_open: :desc)
                   .pluck(
                     :date_open,
                     Arel.sql('COUNT(DISTINCT contest_instances.contest_description_id)'),
                     Arel.sql('MIN(contest_instances.date_closed)'),
                     Arel.sql('MAX(contest_instances.date_closed)')
                   )
                   .map do |date_open, description_count, earliest_close, latest_close|
                     Season.new(
                       date_open: date_open.in_time_zone,
                       description_count: description_count,
                       earliest_close: earliest_close.in_time_zone,
                       latest_close: latest_close.in_time_zone
                     )
                   end
  end

  private

  def description_ids
    ContestInstance.for_container(@container)
                   .not_archived
                   .for_date_open(@date_open)
                   .distinct
                   .pluck(:contest_description_id)
  end

  def process_description(description_id, result)
    description = ContestDescription.find(description_id)

    unless description.active?
      result.skipped << skip_entry(description, 'Contest description is inactive')
      return
    end

    target = newest_instance_for(description)
    if target.nil?
      result.skipped << skip_entry(description, 'No non-archived contest instance found')
      return
    end

    if target.active?
      result.unchanged << {
        contest_description: description,
        contest_instance: target,
        reason: 'Newest instance is already active'
      }
      return
    end

    ActiveRecord::Base.transaction do
      predecessor = description.contest_instances
                               .where(active: true)
                               .where.not(id: target.id)
                               .first

      completed_rounds = []
      if predecessor
        completed_rounds = complete_judging_rounds!(predecessor)
        predecessor.update!(active: false)
      end

      target.update!(active: true)

      result.activated << {
        contest_description: description,
        contest_instance: target
      }
      if predecessor
        result.deactivated << {
          contest_description: description,
          contest_instance: predecessor
        }
      end
      result.rounds_completed.concat(completed_rounds)
    end
  rescue ActiveRecord::RecordInvalid => e
    result.failed << failure_entry(description, e.record.errors.full_messages)
  rescue StandardError => e
    result.failed << failure_entry(description, [e.message])
  end

  def newest_instance_for(description)
    description.contest_instances.not_archived.newest_first.first
  end

  def complete_judging_rounds!(predecessor)
    completed = []
    predecessor.judging_rounds.where(completed: false).order(:round_number).each do |round|
      unless round.complete!
        messages = round.errors.full_messages
        messages = ['Unable to complete judging round'] if messages.empty?
        raise StandardError, "Judging round #{round.round_number}: #{messages.join(', ')}"
      end
      completed << {
        contest_description: predecessor.contest_description,
        contest_instance: predecessor,
        judging_round: round
      }
    end
    completed
  end

  def skip_entry(description, reason)
    {
      contest_description: description,
      reason: reason
    }
  end

  def failure_entry(description, errors)
    {
      contest_description: description,
      contest_name: description.name,
      errors: Array(errors)
    }
  end

  def normalize_date_open(value)
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
    return value.in_time_zone if value.is_a?(Date)

    Time.zone.parse(value.to_s)
  end
end
