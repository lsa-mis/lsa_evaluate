# == Schema Information
#
# Table name: editable_contents
#
#  id         :bigint           not null, primary key
#  page       :string(255)      not null
#  section    :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_editable_contents_on_page_and_section  (page,section) UNIQUE
#
class EditableContent < ApplicationRecord
  validates :page, :section, :content, presence: true
  validates :page, uniqueness: { scope: :section, message: 'and section combination must be unique' }
  has_rich_text :content

  before_save :sanitize_content

  private

  def sanitize_content
    # Strip outer trix-content div if it exists
    return unless content.body.to_html.match?(/<div class="trix-content">/)

    sanitized_html = content.body.to_html.gsub(%r{<div class="trix-content">(.*)</div>}m, '\1')
    content.body = ActionText::Content.new(sanitized_html)
  end
end
