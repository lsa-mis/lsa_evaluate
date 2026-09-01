# frozen_string_literal: true

class BulkJudgingWindowsController < ApplicationController
  before_action :set_container
  before_action :authorize_container_access

  def new
    @judging_rounds = load_judging_rounds
    @bulk_judging_window = BulkJudgingWindowForm.new(cascade_following_rounds: true, cascade_mode: 'minimum_bump')
  end

  def preview
    plans = build_preview_plans
    render json: { plans: serialize_plans(plans) }
  end

  def create
    @bulk_judging_window = BulkJudgingWindowForm.new(form_params)

    if selected_round_ids.blank?
      @judging_rounds = load_judging_rounds
      flash.now[:alert] = 'Please select at least one judging round.'
      return render :new, status: :unprocessable_entity
    end

    unless @bulk_judging_window.valid?
      @judging_rounds = load_judging_rounds
      return render :new, status: :unprocessable_entity
    end

    result = BulkJudgingWindowUpdater.new(
      round_ids: selected_round_ids,
      end_date: @bulk_judging_window.parsed_end_date,
      start_date: @bulk_judging_window.parsed_start_date,
      update_start_date: @bulk_judging_window.update_start_date?,
      cascade: @bulk_judging_window.cascade_enabled?,
      cascade_mode: @bulk_judging_window.cascade_mode_symbol
    ).call

    if result.failed.any?
      @judging_rounds = load_judging_rounds
      flash.now[:alert] = build_failure_message(result)
      return render :new, status: :unprocessable_entity
    end

    redirect_to container_path(@container), notice: build_success_message(result)
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def authorize_container_access
    authorize @container, :manage_judging?
  end

  def load_judging_rounds
    JudgingRound.joins(contest_instance: { contest_description: :container })
                .where(contest_descriptions: { container_id: @container.id })
                .includes(contest_instance: :contest_description)
                .order('contest_descriptions.name', 'contest_instances.date_open', 'judging_rounds.round_number')
  end

  def selected_round_ids
    params[:judging_round_ids]&.keys || []
  end

  def form_params
    params.require(:bulk_judging_window_form).permit(
      :end_date,
      :start_date,
      :update_start_date,
      :cascade_following_rounds,
      :cascade_mode
    )
  end

  def build_preview_plans
    end_date = params[:end_date]
    start_date = params[:start_date]
    update_start_date = ActiveModel::Type::Boolean.new.cast(params[:update_start_date])
    cascade_mode = params[:cascade_mode].presence || 'minimum_bump'
    round_ids = params[:judging_round_ids] || []

    JudgingRound.where(id: round_ids).includes(contest_instance: :contest_description).map do |round|
      plan = JudgingRoundDateCascadePlanner.new(
        round,
        proposed_end_date: end_date,
        proposed_start_date: update_start_date ? start_date : nil,
        mode: cascade_mode
      ).call

      {
        round: round,
        plan: plan
      }
    end
  end

  def serialize_plans(plans)
    plans.map do |entry|
      round = entry[:round]
      plan = entry[:plan]

      {
        round_id: round.id,
        contest_name: round.contest_instance.contest_description.name,
        instance_label: instance_label(round.contest_instance),
        round_number: round.round_number,
        conflicts: plan[:conflicts],
        changes: plan[:affected_rounds].map do |change|
          {
            round_number: change.round.round_number,
            field: change.field.to_s,
            from: I18n.l(change.from, format: :long),
            to: I18n.l(change.to, format: :long),
            reason: change.reason
          }
        end
      }
    end
  end

  def instance_label(instance)
    "#{I18n.l(instance.date_open, format: :short)} – #{I18n.l(instance.date_closed, format: :short)}"
  end

  def build_success_message(result)
    parts = ["Updated #{result.updated.size} judging round#{'s' unless result.updated.size == 1}."]
    if result.cascaded.any?
      parts << "#{result.cascaded.size} additional date adjustment#{'s' unless result.cascaded.size == 1} applied to following rounds."
    end
    parts.join(' ')
  end

  def build_failure_message(result)
    result.failed.map do |failure|
      "#{failure[:contest_name]} Round #{failure[:round_number]}: #{failure[:errors].join(', ')}"
    end.join('; ')
  end
end
