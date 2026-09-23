# frozen_string_literal: true

class BulkContestInstanceActivationsController < ApplicationController
  REPORT_CACHE_TTL = 15.minutes

  before_action :set_container
  before_action :authorize_container_access

  def new
    @seasons = BulkContestInstanceActivator.available_seasons_for(@container)
    @bulk_activation = BulkContestInstanceActivationForm.new(date_open: prefills_date_open)
    @season_instances = season_instances_for(@bulk_activation.parsed_date_open)
  end

  def create
    @bulk_activation = BulkContestInstanceActivationForm.new(form_params)
    @seasons = BulkContestInstanceActivator.available_seasons_for(@container)

    unless @bulk_activation.valid?
      @season_instances = season_instances_for(@bulk_activation.parsed_date_open)
      flash.now[:alert] = @bulk_activation.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    @season_instances = season_instances_for(@bulk_activation.parsed_date_open)

    if @season_instances.empty?
      flash.now[:alert] = 'No inactive contest instances found for the selected open date.'
      return render :new, status: :unprocessable_entity
    end

    result = BulkContestInstanceActivator.new(
      container: @container,
      date_open: @bulk_activation.parsed_date_open
    ).call

    store_activation_report(serialize_report(result))

    if result.failed.any? && result.activated.empty? && result.unchanged.empty?
      flash[:alert] = 'Bulk activation could not be completed. See the report for details.'
    elsif result.failed.any?
      flash[:alert] = 'Bulk activation completed with some failures. See the report for details.'
    elsif result.activated.any?
      flash[:notice] = 'Contest instances were successfully activated.'
    else
      flash[:alert] = 'No contest instances were activated. See the report for details.'
    end

    redirect_to container_path(@container)
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def authorize_container_access
    authorize @container, :access_contest_instances?
  end

  def form_params
    params.require(:bulk_contest_instance_activation_form).permit(:date_open, :confirmed)
  end

  def prefills_date_open
    return params[:date_open] if params[:date_open].present?
    return @seasons.first.date_open if @seasons.any?

    nil
  end

  def season_instances_for(date_open)
    return ContestInstance.none if date_open.blank?

    ContestInstance.for_container(@container)
                   .inactive
                   .not_archived
                   .for_date_open(date_open)
                   .includes(:contest_description)
                   .order('contest_descriptions.name')
  end

  def store_activation_report(report)
    key = "bulk_activation_report/#{current_user.id}/#{@container.id}/#{SecureRandom.uuid}"
    Rails.cache.write(
      key,
      report.merge('container_id' => @container.id),
      expires_in: REPORT_CACHE_TTL
    )
    session[:bulk_activation_report_key] = key
  end

  def serialize_report(result)
    {
      activated: result.activated.map { |entry| report_instance_entry(entry) },
      deactivated: result.deactivated.map { |entry| report_instance_entry(entry) },
      rounds_completed: result.rounds_completed.map { |entry| report_round_entry(entry) },
      skipped: result.skipped.map { |entry| report_skip_entry(entry) },
      failed: result.failed.map { |entry| report_failure_entry(entry) },
      unchanged: result.unchanged.map { |entry| report_instance_entry(entry).merge('reason' => entry[:reason]) }
    }
  end

  def report_instance_entry(entry)
    instance = entry[:contest_instance]
    description = entry[:contest_description]
    {
      'contest_name' => description.name,
      'instance_id' => instance.id,
      'date_open' => instance.date_open&.iso8601,
      'date_closed' => instance.date_closed&.iso8601
    }
  end

  def report_round_entry(entry)
    report_instance_entry(entry).merge(
      'round_number' => entry[:judging_round].round_number
    )
  end

  def report_skip_entry(entry)
    {
      'contest_name' => entry[:contest_description].name,
      'reason' => entry[:reason]
    }
  end

  def report_failure_entry(entry)
    {
      'contest_name' => entry[:contest_name] || entry[:contest_description]&.name,
      'errors' => entry[:errors]
    }
  end
end
