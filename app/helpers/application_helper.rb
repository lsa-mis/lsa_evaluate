# frozen_string_literal: true

module ApplicationHelper
  def render_editable_content(page, section)
    content_record = EditableContent.find_by(page: page, section: section)
    return unless content_record

    # Convert the rich text content to an HTML-safe string
    content_html = content_record.content.to_s

    # Check if the current user has the `axis_mundi` role
    if current_user&.axis_mundi?
      # Create the edit link with an icon
      edit_link = link_to(edit_editable_content_path(content_record), class: 'edit-link ms-2', title: 'Edit') do
        content_tag(:i, '', class: 'bi bi-pencil')
      end
      # Combine the content and the edit link, marking it as HTML safe
      safe_join([ content_html, edit_link ], ' ').html_safe
    else
      # If the user doesn't have the role, just render the content
      html_escape(content_html)
    end
  end

  def format_datetime(datetime)
    datetime.strftime('%m/%d/%Y %I:%M %p')
  end

  def redirect_back_or_default(default: root_url)
    redirect_to(session.delete(:return_to) || default, anchor: 'top')
  end

  def boolean_to_yes_no(value)
    if value
      content_tag(:span, 'Yes', class: 'text-success fw-bold')
    else
      content_tag(:span, 'No', class: 'text-danger fw-bold')
    end
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

  def label_with_required_class(label_text, is_required)
    content_tag(:label, class: "form-label #{'text-danger' if is_required}") do
      concat label_text
      if is_required
        concat content_tag(:span, '*', class: 'text-danger', style: 'margin-left: -6px;')
        concat content_tag(:span, '(required)', class: 'text-xs', style: 'margin-left: -2px;')
      end
    end
  end
end
