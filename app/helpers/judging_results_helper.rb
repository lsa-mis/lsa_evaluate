# frozen_string_literal: true

module JudgingResultsHelper
  def show_average_rank_column?
    false
  end

  def judging_round_rankings_context(round)
    judges = round.round_judge_assignments.includes(:user).map(&:user).uniq.sort_by do |user|
      [user.last_name.to_s.downcase, user.first_name.to_s.downcase]
    end

    entries = round.entries.distinct.includes(entry_rankings: :user).to_a
    rankings_by_entry_and_judge = entries.each_with_object({}) do |entry, memo|
      memo[entry.id] = entry.entry_rankings.select { |ranking| ranking.judging_round_id == round.id }
                              .index_by(&:user_id)
    end

    sort_judge_id = params[:sort_judge_id].presence&.to_i
  sorted_entries = if sort_judge_id && judges.map(&:id).include?(sort_judge_id)
      entries.sort_by do |entry|
        rankings_by_entry_and_judge[entry.id][sort_judge_id]&.rank || Float::INFINITY
      end
    else
      entries.sort_by do |entry|
        judges.map do |judge|
          rankings_by_entry_and_judge[entry.id][judge.id]&.rank || Float::INFINITY
        end
      end
    end

    {
      judges: judges,
      entries: sorted_entries,
      rankings_by_entry_and_judge: rankings_by_entry_and_judge
    }
  end

  def judging_rankings_sort_path(round, container, contest_description, contest_instance, judge: nil, sort_context: nil)
    anchor = "round-#{round.id}-rankings"
    url_options = { anchor: anchor }
    url_options[:sort_judge_id] = judge.id if judge
    sort_context ||= infer_judging_rankings_sort_context

    if sort_context == :contest_instance
      url_options[:tab] = 'judging-results'
      container_contest_description_contest_instance_path(
        container, contest_description, contest_instance, url_options
      )
    else
      container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, round, url_options
      )
    end
  end

  def judging_rankings_clear_sort_path(round, container, contest_description, contest_instance, sort_context: nil)
    judging_rankings_sort_path(
      round, container, contest_description, contest_instance, sort_context: sort_context
    )
  end

  private

  def infer_judging_rankings_sort_context
    if controller_name == 'contest_instances' && action_name == 'show'
      :contest_instance
    else
      :judging_round
    end
  end
end
