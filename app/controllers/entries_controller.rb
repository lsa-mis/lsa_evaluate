# frozen_string_literal: true

class EntriesController < ApplicationController
  include AvailableContestsConcern
  before_action :set_entry, only: %i[ show edit update destroy soft_delete modal_details ]
  before_action :set_entry_for_toggle_disqualified, only: %i[ toggle_disqualified update_award_outcome ]
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
    @effective_questions = EffectiveApplicationQuestions.for(@entry.contest_instance).map(&:question)
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

      persist_entry_answers!(validator.built_answers)
      ProfileCampusSync.call(profile: entry_applicant_profile, answers: validator.built_answers)
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

    saved = false
    ActiveRecord::Base.transaction do
      update_confirmed_class_level!
      validator = EntryAnswersValidator.new(
        entry: @entry,
        effective_questions: @effective_questions,
        answers_params: params[:entry_answers]
      )
      valid_answers = validator.call

      raise ActiveRecord::Rollback unless valid_answers && @entry.update(entry_update_params)

      persist_entry_answers!(validator.built_answers)
      ProfileCampusSync.call(profile: entry_applicant_profile, answers: validator.built_answers)
      saved = true
    end

    respond_to do |format|
      if saved
        format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @entry }
      else
        prepare_application_questions
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

  def update_award_outcome
    authorize @entry, :update_award_outcome?
    @container = @entry.contest_instance.contest_description.container
    @contest_description = @entry.contest_instance.contest_description
    @contest_instance = @entry.contest_instance
    redirect_path = container_contest_description_contest_instance_path(
      @container, @contest_description, @contest_instance, tab: 'awards'
    )

    if @entry.update(award_outcome_params)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Award outcome saved.'
          prepare_award_outcome_frame
          render 'entry_awards/upsert'
        end
        format.html { redirect_to redirect_path, notice: 'Award outcome saved.' }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @entry.errors.full_messages.to_sentence
          prepare_award_outcome_frame
          render 'entry_awards/upsert', status: :unprocessable_entity
        end
        format.html { redirect_to redirect_path, alert: @entry.errors.full_messages.to_sentence }
      end
    end
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
      :title, :contest_instance_id, :category_id, :entry_file, :confirmed_class_level_id
    )
  end

  # Contest membership is fixed after create. Allowing contest_instance_id on
  # update would let an owner reassign an open entry onto another contest
  # without create-equivalent eligibility / private-access checks.
  def entry_update_params
    params.require(:entry).permit(
      :title, :category_id, :entry_file, :confirmed_class_level_id
    )
  end

  def award_outcome_params
    params.require(:entry).permit(:award_status, :placement).tap do |permitted|
      permitted[:placement] = nil if permitted[:placement].blank?
    end
  end

  def prepare_award_outcome_frame
    @entry = Entry.includes(
      :category,
      { entry_awards: :award },
      { profile: [ :user, :class_level ] }
    ).find(@entry.id)
    @catalog_awards = @container.awards.active.ordered
  end

  # Prefer the entry owner's profile so Axis Mundi (or other non-owner editors)
  # do not read/write their own profile when correcting an applicant entry.
  def entry_applicant_profile
    @entry.profile
  end

  def prepare_application_questions
    return unless @entry&.contest_instance

    profile = entry_applicant_profile
    @effective_questions = EffectiveApplicationQuestions.for(@entry.contest_instance)
    @prefill_values = EntryAnswerDisplayValues.for(
      profile: profile,
      questions: @effective_questions.map(&:question),
      submitted_answers: params[:entry_answers]
    )
    @confirmed_class_level_id = params.dig(:entry, :confirmed_class_level_id).presence ||
                                profile.class_level_id
  end

  def update_confirmed_class_level!
    class_level_id = params.dig(:entry, :confirmed_class_level_id).presence
    if class_level_id.blank?
      @entry.errors.add(:base, 'Class level must be confirmed')
      raise ActiveRecord::Rollback
    end

    # Reload profile so an in-memory built entry is not validated during update.
    # Always target the entry owner's profile — not the signed-in editor's.
    profile = Profile.find(entry_applicant_profile.id)
    return if profile.class_level_id.to_s == class_level_id.to_s

    unless profile.update(class_level_id: class_level_id)
      @entry.errors.merge!(profile.errors)
      raise ActiveRecord::Rollback
    end

    # Keep request-scoped profile copies in sync. On update, @entry.profile is a
    # different AR instance than current_user.profile; without this, answer
    # validation still sees the previous class level.
    @entry.profile.class_level_id = profile.class_level_id
    if current_user.profile&.id == profile.id
      current_user.profile.class_level_id = profile.class_level_id
    end
  end

  def persist_entry_answers!(built_answers)
    built_answers.each do |answer|
      record = @entry.entry_answers.find_or_initialize_by(application_question_id: answer.application_question_id)
      record.value = answer.value
      record.save!
    end
  end
end
