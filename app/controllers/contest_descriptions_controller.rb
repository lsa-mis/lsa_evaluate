class ContestDescriptionsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, only: %i[show edit update destroy eligibility_rules]
  before_action :authorize_contest_description, except: [ :index, :new, :create, :multiple_instances, :create_multiple_instances, :eligibility_rules ]
  before_action :authorize_container_access, only: [ :index, :new, :create, :multiple_instances, :create_multiple_instances ]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @contest_descriptions = policy_scope(@container.contest_descriptions)
  end

  def show; end

  def new
    @contest_description = @container.contest_descriptions.new
    authorize @contest_description
  end

  def edit; end

  def create
    @contest_description = @container.contest_descriptions.new(contest_description_params)
    authorize @contest_description
    handle_save(@contest_description.save, 'created')
  end

  def update
    handle_save(@contest_description.update(contest_description_params), 'updated')
  end

  def multiple_instances
    @contest_descriptions = policy_scope(@container.contest_descriptions.active)
  end

  def create_multiple_instances
    @contest_descriptions = policy_scope(@container.contest_descriptions.where(id: params[:contest_instance][:contest_description_ids]))

    if @contest_descriptions.empty?
      redirect_to multiple_instances_container_contest_descriptions_path(@container), alert: 'Please select at least one contest description.'
      return
    end

    result = ContestDescription.create_multiple_instances(@contest_descriptions, multiple_instance_params, current_user)

    if result[:success]
      redirect_to container_path(@container), notice: "Successfully created #{result[:count]} new contest instances."
    else
      redirect_to multiple_instances_container_contest_descriptions_path(@container), alert: result[:errors].join(', ')
    end
  end

  def destroy
    if @contest_description.destroy
      respond_to do |format|
        format.turbo_stream { redirect_to containers_path, notice: I18n.t('notices.contest_description.destroyed') }
        format.html { redirect_to containers_path, notice: I18n.t('notices.contest_description.destroyed') }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to containers_path, alert: @contest_description.errors.full_messages.to_sentence }
        format.html { redirect_to containers_path, alert: @contest_description.errors.full_messages.to_sentence }
      end
    end
  end

  def eligibility_rules
    authorize @contest_description, :eligibility_rules?
    respond_to do |format|
      format.html {
        render partial: 'eligibility_rules',
        locals: { contest_description: @contest_description }
      }
      format.turbo_stream
    end
  end

  private

  def authorize_contest_description
    authorize @contest_description
  end

  def authorize_container_access
    authorize @container, :access_contest_descriptions?
  end

  def handle_save(success, action)
    respond_to do |format|
      if success
        format.turbo_stream { redirect_to container_path(@container), notice: I18n.t("notices.contest_description.#{action}") }
        format.html { redirect_to container_path(@container), notice: I18n.t("notices.contest_description.#{action}") }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace('contest_description_form', partial: 'contest_descriptions/form', locals: { contest_description: @contest_description }), status: :unprocessable_entity
        }
        format.html { render action_name.to_sym, status: :unprocessable_entity }
      end
    end
  end

  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_contest_description
    @contest_description = ContestDescription.find(params[:id])
  end

  def multiple_instance_params
    params.require(:contest_instance).permit(
      :date_open, :date_closed, :active, :archived, :notes,
      :judging_open, :judging_rounds, :judge_evaluations_complete,
      :maximum_number_entries_per_applicant, :require_pen_name,
      :require_campus_employment_info, :require_finaid_info,
      :has_course_requirement, :course_requirement_description,
      :recletter_required, :transcript_required
    )
  end

  def contest_description_params
    params.require(:contest_description).permit(:created_by, :active, :archived,
                                                :eligibility_rules, :name, :notes,
                                                :short_name,
                                                :container_id)
  end
end
