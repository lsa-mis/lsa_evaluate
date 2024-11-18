class JudgingRoundsController < ApplicationController
  before_action :set_contest_instance
  before_action :set_judging_round, only: [:show, :edit, :update, :destroy]
  before_action :authorize_contest_instance

  def new
    @judging_round = @contest_instance.judging_rounds.build
    @round_number = @contest_instance.judging_rounds.count + 1
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
    params.require(:judging_round).permit(:round_number, :start_date, :end_date)
  end
end
