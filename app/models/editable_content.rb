# frozen_string_literal: true

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
class EditableContent < ApplicationRecord
  validates :page, :section, :content, presence: true
  validates :page, uniqueness: { scope: :section, message: 'and section combination must be unique' }
  has_rich_text :content

  def display_name
    "#{self.page.titleize} #{self.section.titleize}"
  end
end
