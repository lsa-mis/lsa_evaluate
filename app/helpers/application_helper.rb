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
      edit_link = link_to(editable_content_path(content), class: 'edit-link ms-2') do
        content_tag(:i, '', class: 'bi bi-pencil')
      end
      content_html += edit_link
    end
    content_html.html_safe
  end

  def format_datetime(datetime)
    datetime.strftime('%m/%d/%Y %I:%M %p')
  end
end
