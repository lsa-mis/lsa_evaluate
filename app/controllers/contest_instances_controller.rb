class ContestInstancesController < ApplicationController
  before_action :set_contest_instance, only: %i[show edit update destroy]

  # GET /contest_instances
  def index
    @contest_instances = ContestInstance.all
  end

  # GET /contest_instances/:id
  def show; end

  # GET /contest_instances/new
  def new
    @contest_instance = ContestInstance.new
  end

  # GET /contest_instances/:id/edit
  def edit; end

  # POST /contest_instances
  def create
    @contest_instance = ContestInstance.new(contest_instance_params)
    if @contest_instance.save
      redirect_to @contest_instance, notice: 'Contest instance was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /contest_instances/:id
  def update
    if @contest_instance.update(contest_instance_params)
      redirect_to @contest_instance, notice: 'Contest instance was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /contest_instances/:id
  def destroy
    @contest_instance.destroy
    redirect_to contest_instances_url, notice: 'Contest instance was successfully destroyed.'
  end

  private

  def set_contest_instance
    @contest_instance = ContestInstance.find(params[:id])
  end

  def contest_instance_params
    params.require(:contest_instance).permit(:status_id, :contest_description_id, :date_open, :date_closed, :notes,
                                             :judging_open, :judging_rounds, :category_id, :has_course_requirement, :judge_evaluations_complete, :course_requirement_description, :recletter_required, :transcript_required, :maximum_number_entries_per_applicant, :created_by)
  end
end
