# frozen_string_literal: true

# The StaticPagesController class is responsible for handling requests related to static pages.
class StaticPagesController < ApplicationController
  before_action :set_editable_content, only: :home

  def home; end

  private

  def set_editable_content
    @instructions = EditableContent.find_or_create_by(page: 'home', section: 'instructions')
    @description = EditableContent.find_or_create_by(page: 'home', section:  'description')
  end
end
