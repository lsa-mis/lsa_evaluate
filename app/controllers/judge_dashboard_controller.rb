# app/controllers/judge_dashboard_controller.rb
class JudgeDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_judge

  def index
    @judging_assignments = current_user.judging_assignments
                                     .includes(contest_instance: [
                                       contest_description: [ :container ],
                                       judging_rounds: [],
                                       entries: [ :entry_rankings ]
                                     ])
                                     .where(active: true)
                                     .order('judging_rounds.round_number ASC')
  end

  private

  def ensure_judge
    unless current_user.judge?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
