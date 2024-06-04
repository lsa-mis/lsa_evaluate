# frozen_string_literal: true

module ApplicationHelper
  def render_rich_text_without_outer_div(content)
    raw content.body.to_html.gsub(%r{<div class="trix-content">(.*)</div>}m, '\1')
  end
end
