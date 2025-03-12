class ContestInstancesController < ApplicationController
  before_action :set_container
  before_action :set_contest_description
  before_action :set_contest_instance, only: %i[show edit update destroy send_round_results]
  before_action :authorize_container_access

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
        when 'profile_display_name'
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
    @contest_instance.created_by = current_user.email

    if @contest_instance.save
      redirect_to_contest_instance_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @contest_instance.update(contest_instance_params)
      redirect_to_contest_instance_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /contest_instances/:id
  def destroy
    if @contest_instance.destroy
      respond_to do |format|
        format.turbo_stream { redirect_to container_contest_description_contest_instances_path(@container, @contest_description), notice: I18n.t('notices.contest_instance.destroyed') }
        format.html { redirect_to container_contest_description_contest_instances_path(@container, @contest_description), notice: I18n.t('notices.contest_instance.destroyed') }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to container_contest_description_contest_instances_path(@container, @contest_description), alert: @contest_description.errors.full_messages.to_sentence }
        format.html { redirect_to container_contest_description_contest_instances_path(@container, @contest_description), alert: @contest_description.errors.full_messages.to_sentence }
      end
    end
  end

  # POST /containers/:container_id/contest_descriptions/:contest_description_id/contest_instances/:id/send_round_results
  def send_round_results
    authorize @contest_instance, :send_round_results?

    round_id = params[:round_id]
    judging_round = @contest_instance.judging_rounds.find_by(id: round_id)

    if judging_round.nil?
      redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                 alert: 'Judging round not found.'
      return
    end

    if !judging_round.completed?
      redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                 alert: 'Cannot send results for an incomplete judging round.'
      return
    end

    # Get all entries for this round
    entries = judging_round.entries.uniq

    email_count = 0

    # Send an email for each entry
    entries.each do |entry|
      if Rails.env.local?
        ResultsMailer.entry_evaluation_notification(entry, judging_round).deliver_now
      else
        ResultsMailer.entry_evaluation_notification(entry, judging_round).deliver_later
      end
      email_count += 1
    end

    # Increment the emails sent counter for this round
    judging_round.increment!(:emails_sent_count)

    redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
               notice: "Successfully queued #{email_count} evaluation result emails for round #{judging_round.round_number}. This is email batch ##{judging_round.emails_sent_count}."
  end

  private

  def authorize_container_access
    authorize @container, :access_contest_instances?
  end

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
    params.require(:contest_instance).permit(
      :active, :archived, :contest_description_id, :date_open, :date_closed,
      :notes, :judging_open, :judge_evaluations_complete,
      :maximum_number_entries_per_applicant, :require_pen_name,
      :require_campus_employment_info, :require_finaid_info, :created_by,
      :has_course_requirement, :course_requirement_description,
      :recletter_required, :transcript_required,
      :require_internal_comments, :require_external_comments,
      :min_internal_comment_words, :min_external_comment_words,
      category_ids: [], class_level_ids: []
    )
  end
end
