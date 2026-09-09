# frozen_string_literal: true

require 'csv'

class ContainerApplicantsController < ApplicationController
  before_action :set_container
  before_action :authorize_container

  def index
    @query = build_query
    @summary = @query.summary
    @available_years = @query.available_years
    @campuses = Campus.order(:campus_descr)
    @selected_year = @query.year_filter
    @name_filter = params[:name]
    @campus_id_filter = params[:campus_id]

    respond_to do |format|
      format.html do
        @pagy, @profiles = pagy(
          :offset,
          @query.profiles.includes(:user, :campus),
          limit: 25,
          querify: lambda { |query_params|
            query_params.merge!(filter_params.compact)
          }
        )
        @applicants = @query.rows_for(@profiles)
      end
      format.csv do
        applicants = @query.rows_for(@query.profiles.includes(:user, :campus))
        filename = "applicants-in-#{@container.name.parameterize}_#{Time.zone.today}.csv"
        send_data csv_data(applicants),
                  type: 'text/csv; charset=utf-8; header=present',
                  disposition: "attachment; filename=#{filename}"
      end
    end
  end

  def show
    @profile = ContainerApplicantsQuery.new(container: @container, year: ContainerApplicantsQuery::YEAR_ALL)
                                       .profiles
                                       .includes(:user, :campus, :class_level)
                                       .find(params[:id])
    @entries = entries_for_profile(@profile)
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def authorize_container
    authorize @container, :applicants?
  end

  def build_query
    ContainerApplicantsQuery.new(
      container: @container,
      name: params[:name],
      campus_id: params[:campus_id],
      year: params[:year]
    )
  end

  def filter_params
    {
      'name' => params[:name],
      'campus_id' => params[:campus_id],
      'year' => params[:year]
    }
  end

  def entries_for_profile(profile)
    Entry.active
         .where(profile: profile)
         .joins(contest_instance: { contest_description: :container })
         .where(containers: { id: @container.id })
         .includes(:category, :entry_rankings, contest_instance: [ :contest_description, :judging_rounds ])
         .order('contest_instances.date_open DESC', 'entries.created_at DESC')
  end

  def csv_data(applicants)
    CSV.generate do |csv|
      csv << [
        'Last Name', 'First Name', 'Display Name', 'Email', 'Uniqname', 'UMID',
        'Campus', 'Submission Count', 'Contests', 'Years', 'Finalist In'
      ]

      applicants.each do |applicant|
        csv << [
          csv_safe_cell(applicant.legal_last_name),
          csv_safe_cell(applicant.legal_first_name),
          csv_safe_cell(applicant.name),
          csv_safe_cell(applicant.email),
          csv_safe_cell(applicant.uniqname),
          csv_safe_cell(applicant.umid),
          csv_safe_cell(applicant.campus_name),
          applicant.submission_count,
          csv_safe_cell(applicant.contest_names.join('; ')),
          csv_safe_cell(applicant.years.join('; ')),
          csv_safe_cell(applicant.finalist_contest_names.join('; '))
        ]
      end
    end
  end

  def csv_safe_cell(value)
    text = value.to_s
    return text if text.empty?

    text.start_with?('=', '+', '-', '@', "\t", "\r") ? "'#{text}" : text
  end
end
