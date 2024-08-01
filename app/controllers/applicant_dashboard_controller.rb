class ApplicantDashboardController < ApplicationController
  skip_load_and_authorize_resource

  def index
    @profile = current_user.profile
  end
end
