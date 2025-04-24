class ContestDescriptionsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, only: %i[show edit update destroy eligibility_rules]
  before_action :authorize_contest_description, except: [ :index, :new, :create, :eligibility_rules ]
  before_action :authorize_container_access, only: [ :index, :new, :create ]

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
    @container = policy_scope(Container).find(params[:container_id])
  end

  def set_contest_description
    @contest_description = policy_scope(ContestDescription).find(params[:id])
  end

  def contest_description_params
    params.require(:contest_description).permit(:created_by, :active, :archived,
                                                :eligibility_rules, :name, :notes,
                                                :short_name,
                                                :container_id)
  end
end
