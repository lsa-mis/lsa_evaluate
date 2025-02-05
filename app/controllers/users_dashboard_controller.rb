class UsersDashboardController < ApplicationController
  before_action :set_user, only: [ :show ]

  def index
    authorize :users_dashboard
    @pagy, @users = pagy(
      policy_scope(User)
        .order(sort_column => sort_direction)
        .includes(:roles),
      items: 20  # Explicitly set number of items per page
    )
  end

  def show
    authorize :users_dashboard
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def sort_column
    # List of allowed columns for sorting
    sortable_columns = %w[
      principal_name current_sign_in_at last_sign_in_at
      email display_name first_name last_name
    ]
    sortable_columns.include?(params[:sort]) ? params[:sort] : 'current_sign_in_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
