# app/controllers/judge_dashboard_controller.rb
class JudgeDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :judge_dashboard

    # Find contest instances where the judge has at least one active assignment to an incomplete round
    contest_instances_with_incomplete_assigned_rounds = JudgingRound
      .joins(:round_judge_assignments)
      .where(completed: false)
      .where(round_judge_assignments: { user_id: current_user.id, active: true })
      .select(:contest_instance_id)
      .distinct

    @judging_assignments = current_user.judging_assignments
      .joins(:contest_instance)
      .includes(contest_instance: [
        contest_description: [ :container ],
        judging_rounds: [ :round_judge_assignments ],
        entries: [ :entry_rankings ]
      ])
      .where(judging_assignments: { active: true })
      .where(contest_instances: { active: true, id: contest_instances_with_incomplete_assigned_rounds })
      .order('judging_rounds.round_number ASC')

    # Filter to only include rounds that are active and the judge is actively assigned to
    @assigned_rounds = JudgingRound.joins(:round_judge_assignments)
                                   .where(
                                     active: true,
                                     round_judge_assignments: {
                                       user_id: current_user.id,
                                       active: true
                                     }
                                   )
                                   .where(contest_instance_id: @judging_assignments.pluck(:contest_instance_id))

    @entry_rankings = EntryRanking.includes(:judging_round)
                                 .where(user: current_user)
                                 .joins(judging_round: :contest_instance)
                                 .where(judging_rounds: { id: @assigned_rounds.pluck(:id) })
  end
end
