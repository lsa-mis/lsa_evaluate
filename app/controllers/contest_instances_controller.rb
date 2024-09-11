class ContestInstancesController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, except: %i[create_instances_for_selected_descriptions]
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
  def edit; end

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

  def create_instances_for_selected_descriptions
    selected_descriptions_ids = params[:checkbox].values
    transaction = ActiveRecord::Base.transaction do
      selected_descriptions_ids.each do |id|
        last_contest_instance = ContestDescription.find(id.to_i).contest_instances.last
        new_contest_instance = last_contest_instance.dup
        new_contest_instance.created_by = current_user.email
        new_contest_instance.date_open = params[:dates][:date_open]
        new_contest_instance.date_closed = params[:dates][:date_closed]
        raise ActiveRecord::Rollback unless new_contest_instance.save(validate: false)
        new_contest_instance.class_levels << last_contest_instance.class_levels
        new_contest_instance.categories << last_contest_instance.categories
      end
      true
    end
    if transaction 
      redirect_to containers_path, notice: "Contests instances were created for selected descriptions"
    else
      redirect_to containers_path, alert: "Database error creating instances."
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
    params.require(:contest_instance).permit(:contest_description_id, :date_open, :date_closed, :active, :archived, :notes,
                                             :judging_open, :judging_rounds, :category_id, :has_course_requirement,
                                             :judge_evaluations_complete, :course_requirement_description,
                                             :recletter_required, :transcript_required, :maximum_number_entries_per_applicant,
                                             :created_by, category_contest_instances_attributes: [ :id, :category_id, :_destroy ],
                                             class_level_requirements_attributes: [ :id, :class_level_id, :_destroy ])
  end
end
