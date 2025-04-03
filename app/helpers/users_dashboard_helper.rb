# frozen_string_literal: true

module UsersDashboardHelper
  include Pagy::Frontend

  def sort_link(column, title = nil)
    title ||= column.titleize

    # Toggle direction if clicking the same column
    current_direction = params[:direction] || 'desc'
    new_direction = (column == params[:sort] && current_direction == 'asc') ? 'desc' : 'asc'

    icon = sort_icon(column)

    # Create a URL for sorting
    new_params = request.query_parameters.merge(
      sort: column,
      direction: new_direction
    )

    url = users_dashboard_index_path(new_params)

    # Include data attributes for backward compatibility with tests
    data_attributes = {
      sort: column
    }

    # Add filter values if present
    if params[:principal_name_filter].present?
      data_attributes[:principal_name_filter] = params[:principal_name_filter]
    end

    if params[:email_filter].present?
      data_attributes[:email_filter] = params[:email_filter]
    end

    link_to(safe_join([ title, icon ]), url, {
      class: 'text-decoration-none text-dark',
      data: data_attributes
    })
  end

  private

  def sort_icon(column)
    return '' unless params[:sort] == column

    current_direction = params[:direction] || 'desc'
    icon_class = current_direction == 'asc' ? 'bi-caret-up-fill' : 'bi-caret-down-fill'
    content_tag(:i, '', class: [ 'bi', icon_class, 'ms-1' ])
  end
end
