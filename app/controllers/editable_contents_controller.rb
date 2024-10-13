# frozen_string_literal: true

class EditableContentsController < ApplicationController
  before_action :set_editable_content, only: %i[edit update]
  before_action :store_return_location, only: %i[ edit ]

  def index
    authorize EditableContent
    @editable_contents = policy_scope(EditableContent).order(:page, :section)
  end

  def edit
    authorize @editable_content
  end

  def update
    authorize @editable_content
    if @editable_content.update(editable_content_params)
      flash[:notice] = 'Content was successfully updated.'
      redirect_back_or_default
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_editable_content
    @editable_content = EditableContent.find(params[:id])
  end

  def store_return_location
    session[:return_to] = request.referer
  end

  def editable_content_params
    params.require(:editable_content).permit(:page, :section, :content)
  end
end
