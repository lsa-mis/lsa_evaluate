class EntryRankingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_judge
  before_action :set_entry_ranking, only: [ :update ]
  before_action :authorize_entry_ranking, only: [ :update ]
  before_action :load_judging_round
  before_action :ensure_contest_assignment
  before_action :ensure_round_assignment

  def create
    @entry_ranking = EntryRanking.new(entry_ranking_params)
    @entry_ranking.user = current_user
    @entry_ranking.judging_round = @judging_round

    if @entry_ranking.save
      redirect_back(fallback_location: judge_dashboard_path, notice: 'Ranking saved successfully.')
    else
      render json: { errors: @entry_ranking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @entry_ranking.update(entry_ranking_params)
      @entry_ranking.reload
      redirect_back(fallback_location: judge_dashboard_path, notice: 'Ranking updated successfully.')
    else
      render json: { errors: @entry_ranking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_entry_ranking
    @entry_ranking = EntryRanking.find(params[:id])
  end

  def load_judging_round
    @judging_round = if @entry_ranking
      @entry_ranking.judging_round
    else
      JudgingRound.find(entry_ranking_params[:judging_round_id])
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ 'Judging round not found' ] }, status: :unprocessable_entity
  rescue ActionController::ParameterMissing => e
    render json: { errors: [ 'Missing required parameters' ] }, status: :unprocessable_entity
  end

  def authorize_entry_ranking
    return true unless @entry_ranking
    return true if @entry_ranking.user_id == current_user.id

    redirect_to root_path, alert: 'You can only edit your own rankings'
    false
  end

  def ensure_contest_assignment
    return false unless @judging_round
    return false if action_name == 'update' && !authorize_entry_ranking

    unless @judging_round.contest_instance.judge_assigned?(current_user)
      render json: { errors: [ 'You are not assigned to this contest' ] }, status: :unprocessable_entity
      return false
    end
    true
  end

  def ensure_round_assignment
    return false unless @judging_round
    return false if action_name == 'update' && !authorize_entry_ranking

    unless @judging_round.round_judge_assignments.active.exists?(user: current_user)
      render json: { errors: [ 'You are not assigned to this judging round' ] }, status: :unprocessable_entity
      return false
    end
    true
  end

  def entry_ranking_params
    if action_name == 'update'
      params.require(:entry_ranking).permit(
        :rank,
        :internal_comments,
        :external_comments
      )
    else
      params.require(:entry_ranking).permit(
        :entry_id,
        :judging_round_id,
        :rank,
        :internal_comments,
        :external_comments
      )
    end
  rescue ActionController::ParameterMissing => e
    {}
  end

  def ensure_judge
    unless current_user.judge?
      redirect_to root_path, alert: 'Access denied'
      return false
    end
    true
  end
end
