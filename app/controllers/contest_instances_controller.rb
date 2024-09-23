class ContestInstancesController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, except: %i[create_instances_for_selected_descriptions]
  before_action :set_contest_instance, only: %i[show edit update destroy]

  # GET /contest_instances
  def index
    @contest_instances = @contest_description.contest_instances
  end

  def show
    @contest_instance_entries = @contest_instance.entries.active.includes(profile: :user)
    # @contest_instance_entries = @contest_instance.entries

    if params[:sort_column].present? && params[:sort_direction].present?
      sortable_columns = Entry.sortable_columns
      sort_column = params[:sort_column]
      sort_direction = params[:sort_direction]

      if sortable_columns.keys.include?(sort_column) && %w[asc desc].include?(sort_direction)
        sort_sql = sortable_columns[sort_column]

        case sort_column
        when 'profile_display_name', 'pen_name'
          @contest_instance_entries = @contest_instance_entries.joins(:profile)
        when 'profile_user_uniqname'
          @contest_instance_entries = @contest_instance_entries.joins(profile: :user)
        end

        @contest_instance_entries = @contest_instance_entries.order("#{sort_sql} #{sort_direction}")
      end
    end
  end

  # GET /contest_instances/new
  def new
    @contest_instance = @contest_description.contest_instances.new
    @contest_instance.category_contest_instances.build if @contest_instance.category_contest_instances.empty?
    @contest_instance.class_level_requirements.build if @contest_instance.class_level_requirements.empty?
  end

  # GET /contest_instances/:id/edit
  def edit; end

  # POST /contest_instances
  def create
    @contest_instance = @contest_description.contest_instances.new(contest_instance_params)

    respond_to do |format|
      if @contest_instance.save
        format.html { redirect_to_contest_instance_path }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contest_instances/:id
  def update
    respond_to do |format|
      if @contest_instance.update(contest_instance_params)
        format.html { redirect_to_contest_instance_path }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contest_instances/:id
  def destroy
    respond_to do |format|
      if @contest_instance.destroy
        format.html do
          redirect_to container_contest_description_contest_instances_path(@container, @contest_description),
                      notice: 'Contest instance was successfully destroyed.'
        end
      else
        format.html do
          redirect_to container_contest_description_contest_instances_path(@container, @contest_description),
                      alert: 'Failed to destroy the contest instance.'
        end
      end
    end
  end

  def create_instances_for_selected_descriptions
    selected_descriptions_ids = params[:checkbox].values
    success_count = 0
    errors = []

    contest_descriptions = ContestDescription.where(id: selected_descriptions_ids.map(&:to_i))

    contest_descriptions.each do |contest_description|
      last_contest_instance = contest_description.contest_instances.last

      unless last_contest_instance.present?
        errors << "No previous contest instance found for Contest Description ID #{contest_description.id}"
        next
      end

      new_contest_instance = last_contest_instance.dup_with_associations
      new_contest_instance.created_by = current_user.email
      new_contest_instance.date_open = params[:dates][:date_open]
      new_contest_instance.date_closed = params[:dates][:date_closed]

      if new_contest_instance.save
        success_count += 1
      else
        errors << "Failed to create contest instance for Contest Description ID #{contest_description.id}: #{new_contest_instance.errors.full_messages.join(', ')}"
      end
    end

    error_message = "#{success_count} Contest instances were successfully created.<br>" if success_count > 0
    error_message ||= ''
    error_message += "However, errors occurred while creating the following Contest instances:<br>#{errors.join('<br>')}".html_safe if errors.any?

    redirect_to containers_path, alert: error_message
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

  def redirect_to_contest_instance_path
    redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                notice: 'Contest instance was successfully created/updated.'
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
