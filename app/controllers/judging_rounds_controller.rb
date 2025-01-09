class JudgingRoundsController < ApplicationController
  before_action :set_contest_instance
  before_action :set_judging_round, only: [ :show, :edit, :update, :destroy, :activate, :deactivate, :complete, :uncomplete, :update_rankings, :finalize_rankings ]
  before_action :authorize_contest_instance
  before_action :check_edit_warning, only: [ :edit, :update ]

  def show
    @entries = @judging_round.entries.distinct
                .includes(entry_rankings: [ :user ])
                .where(entry_rankings: { judging_round_id: @judging_round.id })
  end

  def new
    @judging_round = @contest_instance.judging_rounds.build
    @round_number = @contest_instance.judging_rounds.count + 1
  end

  def edit
  end

  def create
    @judging_round = @contest_instance.judging_rounds.build(judging_round_params)
    @round_number = @contest_instance.judging_rounds.count + 1

    if @judging_round.save
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully created.'
    else
      flash.now[:alert] = @judging_round.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @judging_round.update(judging_round_params)
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully updated.'
    else
      flash.now[:alert] = @judging_round.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @judging_round.destroy
    redirect_to container_contest_description_contest_instance_judging_assignments_path(
      @container, @contest_description, @contest_instance
    ), notice: 'Judging round was successfully deleted.'
  end

  def activate
    if @judging_round.activate!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully activated.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: @judging_round.errors.full_messages
    end
  end

  def deactivate
    if @judging_round.deactivate!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully deactivated.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: @judging_round.errors.full_messages
    end
  end

  def complete
    if @judging_round.complete!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully completed.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: @judging_round.errors.full_messages
    end
  end

  def uncomplete
    if @judging_round.uncomplete!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully uncompleted.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: @judging_round.errors.full_messages
    end
  end

  def update_rankings
    rankings = params[:rankings]

    begin
      ActiveRecord::Base.transaction do
        # First, get all current rankings for this user and round
        current_rankings = EntryRanking.where(
          judging_round: @judging_round,
          user: current_user
        )

        # Get the entry IDs from the new rankings
        new_entry_ids = rankings.map { |r| r[:entry_id].to_i }

        # Delete rankings for entries that were moved back to available list
        current_rankings.where.not(entry_id: new_entry_ids).destroy_all

        # Update or create rankings for the remaining entries
        rankings.each do |ranking_data|
          entry = Entry.find(ranking_data[:entry_id])
          entry_ranking = EntryRanking.find_or_initialize_by(
            entry: entry,
            judging_round: @judging_round,
            user: current_user
          )

          entry_ranking.rank = ranking_data[:rank]
          entry_ranking.internal_comments = ranking_data[:internal_comments] if ranking_data[:internal_comments]
          entry_ranking.external_comments = ranking_data[:external_comments] if ranking_data[:external_comments]

          # Skip validations for partial saves
          entry_ranking.save(validate: false)
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("available_entries_#{@contest_instance.id}",
                partial: 'judge_dashboard/available_entries',
                locals: {
                  assignment: JudgingAssignment.find_by(
                    contest_instance: @contest_instance,
                    user: current_user
                  )
                }
              ),
              turbo_stream.update("selected_entries_#{@contest_instance.id}",
                partial: 'judge_dashboard/selected_entries',
                locals: {
                  assignment: JudgingAssignment.find_by(
                    contest_instance: @contest_instance,
                    user: current_user
                  )
                }
              )
            ]
          end
          format.json { render json: { success: true } }
        end
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('flash',
            partial: 'shared/flash',
            locals: { message: e.message, type: 'danger' }
          )
        end
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  def finalize_rankings
    entry_rankings = EntryRanking.where(
      judging_round: @judging_round,
      user: current_user
    )

    error_message = nil

    if entry_rankings.count != @judging_round.required_entries_count
      error_message = "Please select and rank exactly #{@judging_round.required_entries_count} entries."
    elsif @judging_round.require_internal_comments && entry_rankings.any? { |r| r.internal_comments.blank? }
      error_message = 'Please provide internal comments for all ranked entries.'
    elsif @judging_round.require_external_comments && entry_rankings.any? { |r| r.external_comments.blank? }
      error_message = 'Please provide external comments for all ranked entries.'
    end

    if error_message
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('flash',
            partial: 'shared/flash',
            locals: { message: error_message, type: 'danger' }
          )
        end
        format.html { redirect_to judge_dashboard_path, alert: error_message }
      end
      return
    end

    begin
      ActiveRecord::Base.transaction do
        # Update all rankings as finalized
        entry_rankings.each do |ranking|
          ranking.update!(finalized: true)
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update('flash',
                partial: 'shared/flash',
                locals: {
                  message: 'Rankings have been finalized successfully.',
                  type: 'success'
                }
              ),
              turbo_stream.update("selected_entries_#{@contest_instance.id}",
                partial: 'judge_dashboard/selected_entries',
                locals: {
                  assignment: JudgingAssignment.find_by(
                    contest_instance: @contest_instance,
                    user: current_user
                  )
                }
              )
            ]
          end
          format.html { redirect_to judge_dashboard_path, notice: 'Rankings have been finalized successfully.' }
        end
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('flash',
            partial: 'shared/flash',
            locals: { message: e.message, type: 'danger' }
          )
        end
        format.html { redirect_to judge_dashboard_path, alert: e.message }
      end
    end
  end

  private

  def set_contest_instance
    @contest_instance = ContestInstance.find(params[:contest_instance_id])
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container
  end

  def set_judging_round
    @judging_round = @contest_instance.judging_rounds.find(params[:id])
  end

  def authorize_contest_instance
    authorize @contest_instance
  end

  def check_edit_warning
    if @judging_round.entry_rankings.exists?
      flash.now[:warning] = 'Warning: This round already has rankings. Editing it may affect existing rankings.'
    elsif @judging_round.start_date <= Time.current
      flash.now[:warning] = 'Warning: This round has already started'
    end
  end

  def judging_round_params
    params.require(:judging_round).permit(
      :round_number,
      :start_date,
      :end_date,
      :require_internal_comments,
      :require_external_comments,
      :min_internal_comment_words,
      :min_external_comment_words,
      :special_instructions,
      :required_entries_count
    )
  end
end
