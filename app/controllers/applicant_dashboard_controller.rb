# app/controllers/applicant_dashboard_controller.rb
class ApplicantDashboardController < ApplicationController
  include AvailableContestsConcern

  def index
    @profile = current_user&.profile
    unless @profile
      redirect_to new_profile_path, alert: 'Please create your profile first.'
      return
    end

    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.visible

    filter_params = params[:filter] || {}
    @department_id = filter_params[:department_id]
    @container_id = filter_params[:container_id]

    available_contests

    if @active_contests.empty?
      flash.now[:notice] = 'There are currently no active contests available for your class level.'
    end

    @entries = Entry.active.where(profile: @profile)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
