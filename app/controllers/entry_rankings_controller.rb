class EntryRankingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_judge
  before_action :ensure_contest_assignment
  before_action :ensure_round_assignment
  
  def create
    @entry_ranking = EntryRanking.find_or_initialize_by(
      entry_id: entry_ranking_params[:entry_id],
      judging_round_id: entry_ranking_params[:judging_round_id],
      user_id: current_user.id
    )
    
    authorize @entry_ranking
    @entry_ranking.rank = entry_ranking_params[:rank]
    
    if @entry_ranking.save
      redirect_back(fallback_location: judge_dashboard_path, notice: 'Ranking saved successfully.')
    else
      redirect_back(fallback_location: judge_dashboard_path, alert: 'Failed to save ranking.')
    end
  end

  private

  def ensure_contest_assignment
    contest_instance = JudgingRound.find(entry_ranking_params[:judging_round_id])
                                 .contest_instance
    
    unless contest_instance.judge_assigned?(current_user)
      redirect_to root_path, alert: 'You are not assigned to this contest'
    end
  end

  def ensure_round_assignment
    round = JudgingRound.find(entry_ranking_params[:judging_round_id])
    
    unless round.round_judge_assignments.active.exists?(user: current_user)
      redirect_to root_path, alert: 'You are not assigned to this judging round'
    end
  end

  def entry_ranking_params
    params.require(:entry_ranking).permit(:entry_id, :judging_round_id, :rank)
  end

  def ensure_judge
    unless current_user.judge?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
