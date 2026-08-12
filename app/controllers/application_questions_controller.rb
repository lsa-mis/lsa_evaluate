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
      :key, :label, :help_text, :field_type, :position, :active, options: {}
    ).tap do |permitted|
      if permitted[:options].is_a?(ActionController::Parameters) || permitted[:options].is_a?(Hash)
        choices = permitted.dig(:options, :choices) || permitted.dig(:options, 'choices')
        if choices.is_a?(String)
          permitted[:options] = { 'choices' => choices.split("\n").map(&:strip).reject(&:blank?) }
        end
      end
    end
  end

  def application_question_update_params
    application_question_params.except(:field_type).tap do |permitted|
      permitted.delete(:key) if @application_question.system?
    end
  end
end
