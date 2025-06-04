class EntryRankingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_judge, except: [ :select_for_next_round ]
  before_action :set_contest_instance
  before_action :set_entry_ranking, only: [ :update, :select_for_next_round, :evaluate ]
  before_action :load_judging_round
  before_action :authorize_entry_ranking, only: [ :update ]
  before_action :ensure_contest_assignment, except: [ :select_for_next_round ]
  before_action :ensure_round_assignment, except: [ :select_for_next_round ]

  def evaluate
    if @entry_ranking.nil?
      @entry_ranking = EntryRanking.new(
        entry_id: params[:entry_id],
        judging_round: @judging_round,
        user: current_user
      )
    end
    render :evaluate
  end

  def create
    @entry_ranking = EntryRanking.new(entry_ranking_params)
    @entry_ranking.user = current_user
    @entry_ranking.judging_round = @judging_round

    if @entry_ranking.save
      redirect_to judge_dashboard_path, notice: 'Entry ranking was successfully created.'
    else
      render json: { errors: @entry_ranking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @entry_ranking.update(entry_ranking_params)
      redirect_to judge_dashboard_path, notice: 'Evaluation updated successfully.'
    else
      render :evaluate
    end
  end

  def select_for_next_round
    authorize @entry_ranking, :select_for_next_round?

    selected = params[:selected_for_next_round] == '1'

    # Update ALL rankings for this entry in this round, not just one
    entry = @entry_ranking.entry
    judging_round = @entry_ranking.judging_round

    # Update all rankings for this entry
    updated = EntryRanking.where(entry: entry, judging_round: judging_round)
                          .update_all(selected_for_next_round: selected)

    if updated > 0
      Rails.logger.info { "Updated #{updated} rankings for entry #{entry.id} - selected_for_next_round: #{selected}" }

      respond_to do |format|
        format.html {
          redirect_back(fallback_location: container_contest_description_contest_instance_judging_round_path(
            @container, @contest_description, @contest_instance, @judging_round
          ), notice: 'Entry selection updated successfully.')
        }
        format.turbo_stream {
          flash.now[:notice] = 'Entry selection updated successfully'
          render turbo_stream: [
            turbo_stream.replace(
              "selected_for_next_round_#{entry.id}",
              partial: 'judging_rounds/entry_checkbox',
              locals: {
                entry: entry,
                judging_round: judging_round,
                container: @container,
                contest_description: @contest_description,
                contest_instance: @contest_instance
              }
            ),
            turbo_stream.replace('flash', partial: 'shared/flash_messages')
          ]
        }
      end
    else
      respond_to do |format|
        format.html {
          redirect_back(fallback_location: container_contest_description_contest_instance_judging_round_path(
            @container, @contest_description, @contest_instance, @judging_round
          ), alert: 'Failed to update entry selection.')
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "selected_for_next_round_#{entry.id}",
            partial: 'judging_rounds/entry_checkbox',
            locals: {
              entry: entry,
              judging_round: judging_round,
              container: @container,
              contest_description: @contest_description,
              contest_instance: @contest_instance
            }
          )
        }
      end
    end
  end

  private

  def set_entry_ranking
    @entry_ranking = if params[:id] && params[:id] != 'new'
      EntryRanking.find_by(id: params[:id])
    elsif params[:entry_id]
      EntryRanking.find_by(
        entry_id: params[:entry_id],
        judging_round: @judging_round,
        user: current_user
      )
    end
  end

  def load_judging_round
    @judging_round = if @entry_ranking&.judging_round
      @entry_ranking.judging_round
    elsif params[:judging_round_id]
      JudgingRound.find(params[:judging_round_id])
    elsif params[:entry_ranking]
      JudgingRound.find(entry_ranking_params[:judging_round_id])
    end

    if @judging_round.nil?
      render json: { errors: [ 'Judging round not found' ] }, status: :unprocessable_entity
      return false
    end
    true
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ 'Judging round not found' ] }, status: :unprocessable_entity
    false
  end

  def set_contest_instance
    @container = Container.find(params[:container_id])
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
    true
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ 'Contest instance not found' ] }, status: :unprocessable_entity
    false
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
