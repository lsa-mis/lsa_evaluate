class ApplicantDashboardController < ApplicationController
  def index
    @profile_prompt = false
    if current_user.profile.present? 
      @profile = current_user.profile
      @profile_exist = true
      if @profile.updated_at < DateTime.now - 3.month
        @profile_prompt = true
      end
      @message = "It's been a while since you've login. Please review and update your profile"
      @title = "Welcome back " + current_user.display_firstname_or_email
    else
      @profile_prompt = true
      @message = "Please create a profile"
      @profile_exist = false
      @profile = nil
      @title = "Welcome " + current_user.display_firstname_or_email
    end
    @entries = Entry.where(profile: @profile)
    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.all
    @active_contests = ContestInstance.active_and_open
    @entries = Entry.where(profile: @profile)
  end
end
