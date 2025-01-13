# app/controllers/judge_dashboard_controller.rb
class JudgeDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :judge_dashboard

    @judging_assignments = current_user.judging_assignments
                                     .includes(contest_instance: [
                                       contest_description: [ :container ],
                                       judging_rounds: [],
                                       entries: [ :entry_rankings ]
                                     ])
                                     .where(active: true)
                                     .order('judging_rounds.round_number ASC')

    @entry_rankings = EntryRanking.includes(:judging_round)
                                 .where(user: current_user)
                                 .joins(judging_round: :contest_instance)
                                 .where(judging_rounds: { contest_instances: { id: @judging_assignments.pluck(:contest_instance_id) } })
  end
end
