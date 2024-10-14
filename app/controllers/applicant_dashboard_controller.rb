# app/controllers/applicant_dashboard_controller.rb
class ApplicantDashboardController < ApplicationController
  def index
    @profile = current_user.profile
    unless @profile
      redirect_to new_profile_path, alert: 'Please create your profile first.'
      return
    end

    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.visible

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

  private

  def available_contests
    @active_contests = ContestInstance.active_and_open
                                      .for_class_level(@profile.class_level_id)
                                      .with_public_visibility
                                      .available_for_profile(@profile)
                                      .includes(contest_description: { container: :visibility })
                                      .order('containers.name ASC')
                                      .distinct

    # Apply filtering if container_id is provided
    if params[:container_id].present?
      @active_contests = @active_contests.where(contest_descriptions: { container_id: params[:container_id] })
    end

    if params[:department_id].present?
      @active_contests = @active_contests.joins(contest_description: :container)
                                         .where(containers: { department_id: params[:department_id] })
    end

    # Update @active_contests_by_container after filtering
    @active_contests_by_container = @active_contests.group_by do |contest|
      contest.contest_description.container
    end
  end
end
