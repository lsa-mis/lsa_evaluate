# frozen_string_literal: true

class ContainerWinnersController < ApplicationController
  before_action :set_container
  before_action :authorize_container

  def show
    @query = build_query
    @entries = @query.entries
    @contest_descriptions = @container.contest_descriptions.order(:name)
    @contest_instances = contest_instances_for_filter
  end

  def export_roster
    csv_data = AwardsExportService.new(
      entries: build_query.entries,
      title: "#{@container.name} - Award roster"
    ).roster_csv

    send_data csv_data,
              type: 'text/csv; charset=utf-8; header=present',
              disposition: "attachment; filename=#{filename('award-roster')}"
  end

  def export_disbursement
    csv_data = AwardsExportService.new(
      entries: build_query.entries,
      title: "#{@container.name} - Award disbursement"
    ).disbursement_csv

    send_data csv_data,
              type: 'text/csv; charset=utf-8; header=present',
              disposition: "attachment; filename=#{filename('award-disbursement')}"
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:id])
  end

  def authorize_container
    authorize @container, :winners?
  end

  def build_query
    ContainerWinnersQuery.new(
      container: @container,
      contest_description_id: params[:contest_description_id],
      contest_instance_id: params[:contest_instance_id],
      award_status: params[:award_status],
      award_kind: params[:award_kind]
    )
  end

  def contest_instances_for_filter
    scope = ContestInstance.joins(:contest_description).where(contest_descriptions: { container_id: @container.id })
    if params[:contest_description_id].present?
      scope = scope.where(contest_description_id: params[:contest_description_id])
    end
    scope.includes(:contest_description).order('contest_instances.date_open DESC')
  end

  def filename(kind)
    "#{kind}-#{@container.name.parameterize}_#{Time.zone.today}.csv"
  end
end
