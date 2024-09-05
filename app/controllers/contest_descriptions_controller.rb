class ContestDescriptionsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, only: %i[show edit update destroy]

  def index
    @contest_descriptions = ContestDescription.all
  end

  def show; end

  def new
    @contest_description = @container.contest_descriptions.new
  end

  def edit; end

  def create
    @contest_description = @container.contest_descriptions.new(contest_description_params)

    respond_to do |format|
      if @contest_description.save
        format.html { redirect_to container_contest_description_path(@container, @contest_description), notice: 'Contest description was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @contest_description.update(contest_description_params)
        format.html { redirect_to container_contest_description_path(@container, @contest_description), notice: 'Contest description was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def contest_descriptions_for_container
    @contest_descriptions = @container.contest_descriptions
  end

  def destroy
    @contest_description.destroy

    respond_to do |format|
      format.html { redirect_to containers_path, notice: 'Contest description was successfully destroyed.' }
    end
  end

  private
  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_contest_description
    @contest_description = ContestDescription.find(params[:id])
  end

  def contest_description_params
    params.require(:contest_description).permit(:created_by, :eligibility_rules, :name, :notes, :short_name,
                                                :container_id, :status_id)
  end
end
