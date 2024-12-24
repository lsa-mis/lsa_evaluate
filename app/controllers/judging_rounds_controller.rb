class JudgingRoundsController < ApplicationController
  before_action :set_contest_instance
  before_action :set_judging_round, only: [ :show, :edit, :update, :destroy, :activate, :deactivate, :complete, :uncomplete ]
  before_action :authorize_contest_instance
  before_action :check_edit_warning, only: [ :edit, :update ]

  def show
    @entries = @judging_round.entries.distinct.includes(:entry_rankings)
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
      if judging_round_params[:active] == '1' && !@judging_round.active
        if @judging_round.activate!
          redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
            @container, @contest_description, @contest_instance, @judging_round
          ), notice: 'Judging round was successfully updated and activated.'
        else
          redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
            @container, @contest_description, @contest_instance, @judging_round
          ), alert: @judging_round.errors.full_messages.join(', ')
        end
      else
        redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
          @container, @contest_description, @contest_instance, @judging_round
        ), notice: 'Judging round was successfully updated.'
      end
    else
      flash.now[:alert] = @judging_round.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  def activate
    if @judging_round.activate!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully activated.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Failed to activate judging round, be sure previous round is completed.'
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
      ), alert: 'Failed to deactivate judging round.'
    end
  end

  def complete
    if @judging_round.complete!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round was successfully completed. You can now review rankings and select entries for the next round.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Failed to mark judging round as completed, be sure previous rounds are completed first.'
    end
  end

  def uncomplete
    if @judging_round.uncomplete!
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judging round completion status was successfully removed.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Failed to remove judging round completion status.'
    end
  end

  private

  def set_contest_instance
    @container = Container.find(params[:container_id])
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
  end

  def set_judging_round
    @judging_round = @contest_instance.judging_rounds.find(params[:id])
  end

  def authorize_contest_instance
    authorize @contest_instance, :manage_judges?
  end

  def judging_round_params
    params.require(:judging_round).permit(
      :round_number,
      :start_date,
      :end_date,
      :active,
      :require_internal_comments,
      :require_external_comments,
      :min_internal_comment_words,
      :min_external_comment_words,
      :special_instructions
    )
  end

  def editing_after_start?
    @judging_round.start_date && @judging_round.start_date <= Time.current
  end

  def check_edit_warning
    @show_warning = editing_after_start?
  end
end
