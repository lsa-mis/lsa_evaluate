class UsersDashboardController < ApplicationController
  before_action :set_user, only: [ :show ]

  def index
    authorize :users_dashboard
    users = policy_scope(User).includes(:roles)

    # Filter by principal_name if a search parameter is present
    if params[:principal_name_filter].present?
      users = users.where("principal_name LIKE ?", "#{params[:principal_name_filter]}%")
    end

    # Filter by email if a search parameter is present
    if params[:email_filter].present?
      users = users.where("email LIKE ?", "#{params[:email_filter]}%")
    end

    @pagy, @users = pagy(
      :offset,
      users.order(sort_column => sort_direction),
      limit: 20,
      querify: lambda { |p|
        p.merge!(
          {
            'principal_name_filter' => params[:principal_name_filter],
            'email_filter' => params[:email_filter]
          }.compact
        )
      }
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
