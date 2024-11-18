class EntryRankingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_judge
  
  def create
    @entry_ranking = EntryRanking.find_or_initialize_by(
      entry_id: entry_ranking_params[:entry_id],
      judging_round_id: entry_ranking_params[:judging_round_id],
      user_id: current_user.id
    )
    
    @entry_ranking.rank = entry_ranking_params[:rank]
    
    if @entry_ranking.save
      redirect_back(fallback_location: judge_dashboard_path, notice: 'Ranking saved successfully.')
    else
      redirect_back(fallback_location: judge_dashboard_path, alert: 'Failed to save ranking.')
    end
  end

  private

  def entry_ranking_params
    params.require(:entry_ranking).permit(:entry_id, :judging_round_id, :rank)
  end

  def ensure_judge
    unless current_user.judge?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
