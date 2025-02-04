# frozen_string_literal: true

module UsersDashboardHelper
  include Pagy::Frontend

  def sort_link(column, title = nil)
    title ||= column.titleize
    direction = (column == params[:sort] && params[:direction] == 'asc') ? 'desc' : 'asc'
    icon = sort_icon(column, direction)
    link_to(safe_join([ title, icon ]), '#', data: { sort: column }, class: 'text-decoration-none text-dark')
  end

  private

  def sort_icon(column, direction)
    return '' unless params[:sort] == column

    icon_class = direction == 'asc' ? 'bi-caret-up-fill' : 'bi-caret-down-fill'
    content_tag(:i, '', class: [ 'bi', icon_class, 'ms-1' ])
  end
end
