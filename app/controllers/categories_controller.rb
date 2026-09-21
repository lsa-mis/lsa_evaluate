# frozen_string_literal: true

class CategoriesController < ApplicationController
  before_action :set_container
  before_action :set_category, only: %i[edit update destroy]
  before_action :authorize_container

  def index
    @categories = @container.categories.ordered
  end

  def new
    @category = @container.categories.new
  end

  def create
    @category = @container.categories.new(category_params)
    if @category.save
      redirect_to container_categories_path(@container), notice: 'Category was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to container_categories_path(@container), notice: 'Category was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to container_categories_path(@container), notice: 'Category was successfully deleted.'
    else
      redirect_to container_categories_path(@container),
                  alert: @category.errors.full_messages.to_sentence.presence || 'Unable to delete category.'
    end
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def set_category
    @category = @container.categories.find(params[:id])
  end

  def authorize_container
    authorize @container, :update?
  end

  def category_params
    params.require(:category).permit(:kind, :description)
  end
end
