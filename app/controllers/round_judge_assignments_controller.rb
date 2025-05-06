class RoundJudgeAssignmentsController < ApplicationController
  before_action :set_judging_round
  before_action :set_round_judge_assignment, only: [:destroy]
  before_action :authorize_judging_round

  def index
    @round_judge_assignments = @judging_round.round_judge_assignments.includes(:user)
    @available_judges = @judging_round.contest_instance.judges
                         .where.not(id: @round_judge_assignments.pluck(:user_id))
  end

  def create
    @round_judge_assignment = @judging_round.round_judge_assignments.build(round_judge_assignment_params)

    if @round_judge_assignment.save
      redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
        @container, @contest_description, @contest_instance, @judging_round
      ), notice: 'Judge was successfully assigned to round.'
    else
      redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
        @container, @contest_description, @contest_instance, @judging_round
      ), alert: @round_judge_assignment.errors.full_messages.join(', ')
    end
  end

  def destroy
    @round_judge_assignment.destroy
    redirect_to container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
      @container, @contest_description, @contest_instance, @judging_round
    ), notice: 'Judge was removed from round.'
  end

  private

  def set_judging_round
    @container = policy_scope(Container).find(params[:container_id])
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
    @judging_round = @contest_instance.judging_rounds.find(params[:judging_round_id])
  end

  def set_round_judge_assignment
    @round_judge_assignment = @judging_round.round_judge_assignments.find(params[:id])
  end

  def authorize_judging_round
    authorize @judging_round, :manage_judges?
  end

  def round_judge_assignment_params
    params.require(:round_judge_assignment).permit(:user_id)
  end
end
