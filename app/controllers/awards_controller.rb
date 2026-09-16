# frozen_string_literal: true

class AwardsController < ApplicationController
  before_action :set_container
  before_action :set_award, only: %i[edit update destroy]
  before_action :authorize_container

  def index
    @awards = @container.awards.ordered
  end

  def new
    @award = @container.awards.new(kind: 'primary', active: true)
  end

  def create
    @award = @container.awards.new(award_params)
    if @award.save
      redirect_to container_awards_path(@container), notice: 'Award was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @award.update(award_params)
      redirect_to container_awards_path(@container), notice: 'Award was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @award.destroy
      redirect_to container_awards_path(@container), notice: 'Award was successfully deleted.'
    else
      redirect_to container_awards_path(@container),
                  alert: @award.errors.full_messages.to_sentence.presence || 'Unable to delete award.'
    end
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def set_award
    @award = @container.awards.find(params[:id])
  end

  def authorize_container
    authorize @container, :update?
  end

  def award_params
    permitted = [ :name, :default_amount, :default_shortcode, :description, :active ]
    permitted << :kind unless @award&.kind_locked?
    params.require(:award).permit(*permitted)
  end
end
