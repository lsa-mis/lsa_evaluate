# frozen_string_literal: true

# The StaticPagesController class is responsible for handling requests related to static pages.
class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home]

  def home; end
end
