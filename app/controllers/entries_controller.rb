# frozen_string_literal: true

class EntriesController < ApplicationController
  include AvailableContestsConcern
  before_action :set_entry, only: %i[ show edit update destroy soft_delete modal_details ]
  before_action :set_entry_for_toggle_disqualified, only: %i[ toggle_disqualified ]
  before_action :set_entry_for_profile, only: %i[ applicant_profile ]
  before_action :authorize_entry, only: %i[show edit update destroy]
  before_action :authorize_index, only: [ :index ]

  def index
    @entries = policy_scope(Entry)
  end

  def show
    authorize @entry
  end

  def modal_details
    authorize @entry, :show?
    render layout: false
  end

  def new
    contest_instance_id = params[:contest_instance_id]
    @entry = Entry.new(
      contest_instance_id: contest_instance_id,
      profile: current_user.profile
    )
    authorize @entry
    prepare_application_questions
  end

  def edit
    authorize @entry
    prepare_application_questions
  end

  def create
    @entry = current_user.profile.entries.build(entry_params)
    authorize @entry
    prepare_application_questions

    saved = false
    ActiveRecord::Base.transaction do
      update_confirmed_class_level!
      validator = EntryAnswersValidator.new(
        entry: @entry,
        effective_questions: @effective_questions,
        answers_params: params[:entry_answers]
      )
      valid_answers = validator.call

      raise ActiveRecord::Rollback unless valid_answers && @entry.save

      validator.built_answers.each do |answer|
        answer.entry = @entry
        answer.save!
      end
      saved = true
    end

    if saved
      redirect_to applicant_dashboard_path, notice: 'Entry was successfully created.'
    else
      prepare_application_questions
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @entry
    prepare_application_questions
    respond_to do |format|
      if @entry.update(entry_params)
        format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @entry
    @entry.destroy!

    respond_to do |format|
      format.html { redirect_to entries_url, notice: 'Entry was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def soft_delete
    authorize @entry, :soft_delete?
    if @entry.soft_deletable?
      if @entry.update(deleted: true)
        @profile = current_user.profile
        @entries = Entry.active.where(profile: @profile)
        available_contests

        flash.now[:notice] = 'Entry was successfully removed.'
        respond_to do |format|
          format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully removed.' }
          format.turbo_stream
        end
      else
        flash.now[:alert] = 'Failed to remove entry.'
        respond_to do |format|
          format.html { redirect_to applicant_dashboard_path, alert: 'Failed to remove entry.' }
          format.turbo_stream
        end
      end
    else
      flash.now[:alert] = 'Cannot delete entry after contest has closed.'
      respond_to do |format|
        format.html { redirect_to applicant_dashboard_path, alert: 'Cannot delete entry after contest has closed.' }
        format.turbo_stream
      end
    end
  end

  def toggle_disqualified
    authorize @entry, :toggle_disqualified?
    @entry.toggle!(:disqualified)
    redirect_to request.referer || root_path, notice: 'Entry disqualification status has been updated.'
  end

  def applicant_profile
    authorize @entry, :view_applicant_profile?
    @profile = @entry.profile

    if @profile.user == current_user || current_user.axis_mundi?
      @entries = Entry.active.where(profile: @profile)
    else
      admin_role_ids = Role.where(kind: [ 'Collection Administrator', 'Collection Manager' ]).pluck(:id)
      admin_container_ids = current_user.assignments
                                      .where(role_id: admin_role_ids)
                                      .pluck(:container_id)

      @entries = Entry.active
                     .where(profile: @profile)
                     .joins(contest_instance: { contest_description: :container })
                     .where(containers: { id: admin_container_ids })
    end
  end

  private

  def set_entry
    @entry = policy_scope(Entry).find(params[:id])
  end

  def set_entry_for_toggle_disqualified
    @entry = Entry.find(params[:id])
  end

  def set_entry_for_profile
    @entry = policy_scope(Entry).find(params[:id])
  end

  def authorize_entry
    authorize @entry
  end

  def authorize_index
    authorize Entry
  end

  def entry_params
    params.require(:entry).permit(
      :title, :disqualified, :deleted, :contest_instance_id,
      :profile_id, :category_id, :entry_file, :confirmed_class_level_id
    )
  end

  def prepare_application_questions
    return unless @entry&.contest_instance

    @effective_questions = EffectiveApplicationQuestions.for(@entry.contest_instance)
    @prefill_values = ApplicationQuestionPrefill.for(
      profile: current_user.profile,
      questions: @effective_questions.map(&:question)
    )
    @confirmed_class_level_id = params.dig(:entry, :confirmed_class_level_id).presence ||
                                current_user.profile.class_level_id
  end

  def update_confirmed_class_level!
    class_level_id = params.dig(:entry, :confirmed_class_level_id).presence
    if class_level_id.blank?
      @entry.errors.add(:base, 'Class level must be confirmed')
      raise ActiveRecord::Rollback
    end

    current_user.profile.update!(class_level_id: class_level_id)
  end
end
