# frozen_string_literal: true

class EntryAwardsController < ApplicationController
  before_action :set_nested
  before_action :authorize_awards
  before_action :set_entry_award, only: %i[update destroy]

  def create
    saved = false

    Entry.transaction do
      @entry = @contest_instance.entries.active.lock.find(params[:entry_id])
      @entry_award = @entry.entry_awards.new(create_entry_award_params)
      authorize @entry_award
      saved = @entry_award.save
    end

    if saved
      respond_with_entry_frame(notice: 'Prize assigned.')
    else
      respond_with_entry_frame(
        alert: @entry_award.errors.full_messages.to_sentence,
        status: :unprocessable_entity
      )
    end
  end

  def update
    authorize @entry_award
    @entry = @entry_award.entry

    if @entry_award.update(update_entry_award_params)
      respond_with_entry_frame(notice: 'Prize updated.')
    else
      respond_with_entry_frame(
        alert: @entry_award.errors.full_messages.to_sentence,
        status: :unprocessable_entity
      )
    end
  end

  def destroy
    authorize @entry_award
    @entry = @entry_award.entry
    @entry_award.destroy!
    respond_with_entry_frame(notice: 'Prize removed.')
  end

  private

  def set_nested
    @container = policy_scope(Container).find(params[:container_id])
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
  end

  def set_entry_award
    @entry_award = EntryAward.joins(:entry).where(entries: { contest_instance_id: @contest_instance.id }).find(params[:id])
  end

  def authorize_awards
    authorize @contest_instance, :manage_awards?
  end

  def create_entry_award_params
    params.require(:entry_award).permit(:award_id, :amount, :shortcode, :notes)
  end

  def update_entry_award_params
    params.require(:entry_award).permit(:amount, :shortcode, :notes)
  end

  def load_award_entry(entry_id)
    Entry.includes(
      :category,
      { entry_awards: :award },
      { profile: [ :user, :class_level ] }
    ).find(entry_id)
  end

  def respond_with_entry_frame(notice: nil, alert: nil, status: :ok)
    @entry = load_award_entry(@entry.id)
    @catalog_awards = @container.awards.active.ordered
    redirect_path = container_contest_description_contest_instance_path(
      @container, @contest_description, @contest_instance, tab: 'awards'
    )

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice if notice
        flash.now[:alert] = alert if alert
        render :upsert, status: status
      end
      format.html { redirect_to redirect_path, notice: notice, alert: alert }
    end
  end
end
