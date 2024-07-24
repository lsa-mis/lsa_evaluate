# frozen_string_literal: true

# The StaticPagesController class is responsible for handling requests related to static pages.
class StaticPagesController < ApplicationController
  def home
    @departments = Department.all
    @class_levels = ClassLevel.all
    @containers = Container.all
  end
end
