# frozen_string_literal: true

module ApplicationHelper
  def render_rich_text_without_outer_div(content)
    raw content.body.to_html.gsub(%r{<div class="trix-content">(.*)</div>}m, '\1')
  end

  def render_editable_content(page, section)
    content = EditableContent.find_by(page:, section:)
    return unless content

    content_html = render_rich_text_without_outer_div(content.content)
    if current_user&.axis_mundi?
      edit_link = link_to(edit_editable_content_path(content), class: 'edit-link ms-2') do
        content_tag(:i, '', class: 'bi bi-pencil')
      end
      content_html += edit_link
    end
    content_html.html_safe
  end

  def format_datetime(datetime)
    datetime.strftime('%m/%d/%Y %I:%M %p')
  end

  def redirect_back_or_default(default: root_url)
    redirect_to(session.delete(:return_to) || default, anchor: 'top')
  end

  def boolean_to_yes_no(value)
    value ? 'Yes' : 'No'
  end

  def sortable(column, title, container, contest_description, contest_instance)
    direction = (params[:sort_column] == column && params[:sort_direction] == 'asc') ? 'desc' : 'asc'
    arrow = ''
    if params[:sort_column] == column
      arrow = params[:sort_direction] == 'asc' ? ' ▲' : ' ▼'
    end
    link_to "#{title}#{arrow}".html_safe, container_contest_description_contest_instance_path(
      container,
      contest_description,
      contest_instance,
      sort_column: column,
      sort_direction: direction
    )
  end
end
