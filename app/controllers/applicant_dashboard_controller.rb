class ApplicantDashboardController < ApplicationController
  def index
    @profile = current_user.profile
    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.all
  end
end
