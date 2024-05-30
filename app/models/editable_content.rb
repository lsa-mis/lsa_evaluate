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

# The EditableContent class represents a model that stores editable content in the application.
# It is used to manage and retrieve content that can be dynamically updated by administrators.
# This class inherits from the ApplicationRecord class, which provides the basic functionality
# for interacting with the database.
class EditableContent < ApplicationRecord
  validates :page, :section, :content, presence: true
  validates :page, uniqueness: { scope: :section, message: 'and section combination must be unique' }
  has_rich_text :content
end
