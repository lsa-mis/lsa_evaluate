class JudgingRoundsController < ApplicationController
  before_action :set_contest_instance
  before_action :set_judging_round, only: [ :show, :edit, :update, :destroy, :activate, :deactivate, :complete, :uncomplete, :update_rankings, :finalize_rankings, :send_instructions ]
  before_action :authorize_contest_instance
  before_action :check_edit_warning, only: [ :edit, :update ]

  def show
    @entries = @judging_round.entries.distinct
                .includes(entry_rankings: [ :user ])
                .where(entry_rankings: { judging_round_id: @judging_round.id })
                .sort_by { |entry| @judging_round.average_rank_for_entry(entry) || Float::INFINITY }
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

  def send_instructions
    if @judging_round.judges.empty?
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'No judges assigned to this round.'
      return
    end

    sent_count = 0
    failed_emails = []

    @judging_round.round_judge_assignments.active.includes(:user).each do |assignment|
      begin
        JudgingInstructionsMailer.send_instructions(assignment).deliver_later
        sent_count += 1
      rescue => e
        failed_emails << assignment.user.email
        Rails.logger.error "Failed to send judging instructions to #{assignment.user.email}: #{e.message}"
      end
    end

    if failed_emails.empty?
      notice_message = "Judging instructions sent successfully to #{sent_count} judge(s)."
    else
      notice_message = "Sent instructions to #{sent_count} judge(s). Failed to send to: #{failed_emails.join(', ')}"
    end

    redirect_to container_contest_description_contest_instance_judging_assignments_path(
      @container, @contest_description, @contest_instance
    ), notice: notice_message
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

        # If this is a full update (multiple rankings sent), handle deletion of unranked entries
        if rankings.length > 1
          # Get the entry IDs from the new rankings that have a rank (not null)
          ranked_entries = rankings.select { |r| r['rank'].present? || r[:rank].present? }
          ranked_entry_ids = ranked_entries.map { |r| r['entry_id'].presence || r[:entry_id].presence }.compact

          # Delete all rankings that are not in the new list
          current_rankings.where.not(entry_id: ranked_entry_ids).destroy_all

          # Update or create rankings only for entries with a rank
          ranked_entries.each do |ranking_data|
            entry_id = ranking_data['entry_id'].presence || ranking_data[:entry_id].presence
            next unless entry_id

            entry = Entry.find(entry_id)
            entry_ranking = EntryRanking.find_or_initialize_by(
              entry: entry,
              judging_round: @judging_round,
              user: current_user
            )

            entry_ranking.rank = ranking_data['rank'].presence || ranking_data[:rank].presence
            entry_ranking.internal_comments = ranking_data['internal_comments'].presence || ranking_data[:internal_comments].presence || entry_ranking.internal_comments
            entry_ranking.external_comments = ranking_data['external_comments'].presence || ranking_data[:external_comments].presence || entry_ranking.external_comments

            # Skip validations for partial saves
            entry_ranking.save(validate: false)
          end
        else
          # This is a single entry update (comment update)
          ranking_data = rankings.first
          entry_id = ranking_data['entry_id'].presence || ranking_data[:entry_id].presence

          if entry_id && ranking_data['rank'].present?
            entry = Entry.find(entry_id)
            entry_ranking = EntryRanking.find_or_initialize_by(
              entry: entry,
              judging_round: @judging_round,
              user: current_user
            )

            entry_ranking.rank = ranking_data['rank'].presence || ranking_data[:rank].presence
            entry_ranking.internal_comments = ranking_data['internal_comments'].presence || ranking_data[:internal_comments].presence || entry_ranking.internal_comments
            entry_ranking.external_comments = ranking_data['external_comments'].presence || ranking_data[:external_comments].presence || entry_ranking.external_comments
            entry_ranking.save(validate: false)
          end
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
