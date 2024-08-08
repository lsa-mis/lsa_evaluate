class ContestInstancesController < ApplicationController
  before_action :set_container
  before_action :set_contest_description
  before_action :set_contest_instance, only: %i[show edit update destroy]

  # GET /contest_instances
  def index
    @contest_instances = @contest_description.contest_instances
  end

  # GET /contest_instances/:id
  def show; end

  # GET /contest_instances/new
  def new
    @contest_instance = @contest_description.contest_instances.new
  end

  # GET /contest_instances/:id/edit
  def edit
    Rails.logger.debug { "Container: #{@container.inspect}" }
    Rails.logger.debug { "Contest Description: #{@contest_description.inspect}" }
    Rails.logger.debug { "Contest Instance: #{@contest_instance.inspect}" }
  end

  # POST /contest_instances
  def create
    @contest_instance = @contest_description.contest_instances.new(contest_instance_params)

    respond_to do |format|
      if @contest_instance.save
        format.html do
          redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                      notice: 'Contest instance was successfully created.'
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contest_instances/:id
  def update
    respond_to do |format|
      if @contest_instance.update(contest_instance_params)
        format.html do
          redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                      notice: 'Contest instance was successfully updated.'
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contest_instances/:id
  def destroy
    @contest_instance.destroy
    respond_to do |format|
      format.html do
        redirect_to container_contest_description_contest_instances_path(@container, @contest_description),
                    notice: 'Contest instance was successfully destroyed.'
      end
    end
  end

  private

  def set_contest_instance
    @contest_instance = @contest_description.contest_instances.find(params[:id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_contest_description
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
  end

  def contest_instance_params
    params.require(:contest_instance).permit(:status_id, :contest_description_id, :date_open, :date_closed, :notes,
                                             :judging_open, :judging_rounds, :category_id, :has_course_requirement, :judge_evaluations_complete, :course_requirement_description, :recletter_required, :transcript_required, :maximum_number_entries_per_applicant, :created_by)
  end
end
