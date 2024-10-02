class ApplicantDashboardController < ApplicationController
  def index
    @profile = current_user.profile
    unless @profile && @profile.class_level_id
      redirect_to edit_profile_path, alert: 'Please complete your profile with your class level information.'
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
  end

  private

  def available_contests
    # @active_contests = ContestInstance.active_and_open
    #                                   .for_class_level(@profile.class_level_id)
    #                                   .joins(contest_description: :container)
    #                                   .includes(contest_description: :container)
    #                                   .order('containers.name ASC')
    #                                   .distinct
    @active_contests = ContestInstance.active_and_open
    .for_class_level(@profile.class_level_id)
    .with_public_visibility
    .includes(contest_description: { container: :visibility })
    .order('containers.name ASC')
    .distinct

    @active_contests_by_container = @active_contests.group_by do |contest|
      contest.contest_description.container
    end
  end
end
