# frozen_string_literal: true

class ApplicationQuestionsController < ApplicationController
  include ApplicationQuestionRequirementsSync

  before_action :set_container
  before_action :set_application_question, only: %i[edit update destroy]
  before_action :authorize_container

  def index
    @application_questions = @container.application_questions.ordered
    @container_requirements = @container.application_question_requirements.index_by(&:application_question_id)
  end

  def new
    @application_question = @container.application_questions.new(
      field_type: 'string',
      active: true,
      position: (@container.application_questions.maximum(:position) || -1) + 1
    )
  end

  def create
    @application_question = @container.application_questions.new(application_question_params)
    if @application_question.save
      redirect_to container_application_questions_path(@container), notice: 'Question was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @application_question.update(application_question_update_params)
      redirect_to container_application_questions_path(@container), notice: 'Question was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @application_question.destroy
      redirect_to container_application_questions_path(@container), notice: 'Question was successfully deleted.'
    else
      redirect_to container_application_questions_path(@container),
                  alert: @application_question.errors.full_messages.to_sentence.presence || 'Unable to delete question.'
    end
  end

  def update_requirements
    sync_application_question_requirements!(@container, params[:requirements])
    redirect_to container_application_questions_path(@container), notice: 'Default requirements were updated.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to container_application_questions_path(@container), alert: e.record.errors.full_messages.to_sentence
  end

  def reorder
    ordered_ids = Array(params[:application_question_ids]).map(&:to_i)
    current_ids = @container.application_questions.pluck(:id)

    unless ordered_ids.any? && ordered_ids.sort == current_ids.sort
      respond_to do |format|
        format.json { head :unprocessable_entity }
        format.html { redirect_to container_application_questions_path(@container), alert: 'Could not reorder questions.' }
      end
      return
    end

    ApplicationQuestion.transaction do
      ordered_ids.each_with_index do |id, index|
        ApplicationQuestion.where(id: id, container_id: @container.id).update_all(position: index)
      end
    end

    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to container_application_questions_path(@container), notice: 'Question order was updated.' }
    end
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def set_application_question
    @application_question = @container.application_questions.find(params[:id])
  end

  def authorize_container
    authorize @container, :update?
  end

  def application_question_params
    params.require(:application_question).permit(
      :label, :help_text, :field_type, :active, options: {}
    ).tap do |permitted|
      normalize_question_options!(permitted)
    end
  end

  def application_question_update_params
    application_question_params.except(:field_type)
  end

  def normalize_question_options!(permitted)
    return if permitted[:options].blank?

    options = permitted[:options]
    options = options.to_h.stringify_keys if options.is_a?(ActionController::Parameters)
    options = options.stringify_keys if options.is_a?(Hash)

    if options['choices'].is_a?(String)
      options['choices'] = options['choices'].split("\n").map(&:strip).reject(&:blank?)
    end

    if options.key?('requires_acceptance')
      options['requires_acceptance'] = options['requires_acceptance'] == '1' || options['requires_acceptance'] == true
    elsif @application_question&.field_type == 'boolean' && @application_question&.custom?
      options['requires_acceptance'] = false
    end

    normalize_default_value_option!(options)

    permitted[:options] = options
  end

  def normalize_default_value_option!(options)
    field_type = @application_question&.field_type || permitted_field_type
    return if field_type.blank?

    return options.except!('default_value', :default_value) if @application_question&.system?

    return unless options.key?('default_value') || options.key?(:default_value)

    raw_default = options['default_value'] || options[:default_value]
    normalized = ApplicationQuestion.normalize_default_value_param(
      field_type,
      raw_default,
      choices: Array(options['choices'])
    )

    if normalized.nil?
      options.except!('default_value', :default_value)
    else
      options['default_value'] = normalized
    end
  end

  def permitted_field_type
    params.dig(:application_question, :field_type)
  end
end
