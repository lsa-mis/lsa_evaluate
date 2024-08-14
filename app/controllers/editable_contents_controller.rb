# frozen_string_literal: true

class EditableContentsController < ApplicationController
  before_action :set_editable_content, only: %i[show edit update]

  def index
    @editable_contents = EditableContent.all
  end

  def show
    @editable_content = EditableContent.find(params[:id])
  end

  def new
    @editable_content = EditableContent.new
  end

  def edit
    session[:return_to] = request.referer
  end


  def update
    if @editable_content.update(editable_content_params)
      redirect_back_or_default(notice: "Content was successfully updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_editable_content
    @editable_content = EditableContent.find(params[:id])
  end

  def editable_content_params
    params.require(:editable_content).permit(:page, :section, :content)
  end
end
