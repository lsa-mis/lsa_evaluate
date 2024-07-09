class ContestDescriptionsController < ApplicationController
  before_action :set_contest_description, only: %i[show edit update destroy]

  def index
    @contest_descriptions = ContestDescription.all
  end

  def show; end

  def new
    @contest_description = ContestDescription.new
  end

  def edit; end

  def create
    @contest_description = ContestDescription.new(contest_description_params)
    if @contest_description.save
      redirect_to @contest_description, notice: 'Contest description was successfully created.'
    else
      render :new
    end
  end

  def update
    if @contest_description.update(contest_description_params)
      redirect_to @contest_description, notice: 'Contest description was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @contest_description.destroy
    redirect_to contest_descriptions_url, notice: 'Contest description was successfully destroyed.'
  end

  private

  def set_contest_description
    @contest_description = ContestDescription.find(params[:id])
  end

  def contest_description_params
    params.require(:contest_description).permit(:created_by, :eligibility_rules, :name, :notes, :short_name,
                                                :container_id, :status_id)
  end
end
