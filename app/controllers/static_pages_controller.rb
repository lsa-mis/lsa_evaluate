# frozen_string_literal: true

# The StaticPagesController class is responsible for handling requests related to static pages.
class StaticPagesController < ApplicationController
  def home
    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.all
  end

  def entrant_content
    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.all
    render partial: 'entrant_content'
  end

  def admin_content
    render 'admin_content'
  end
end
