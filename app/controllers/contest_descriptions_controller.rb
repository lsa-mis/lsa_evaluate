class ContestDescriptionsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, only: %i[show edit update archive unarchive]

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

  def archive
    session[:return_to] = request.referer
    if @contest_description.update(archived: true)
      redirect_back_or_default(notice: "The contest description was archived")
    else
      @container = Container.find(params[:container_id])
      @contest_descriptions = @container.contest_descriptions
      redirect_back_or_default(notice: "Error archiving contest description", alert: true)
    end
  end

  def unarchive
    session[:return_to] = request.referer
    if @contest_description.update(archived: false)
      redirect_back_or_default(notice: "The contest description was unarchived")
    else
      @container = Container.find(params[:container_id])
      @contest_descriptions = @container.contest_descriptions
      redirect_back_or_default(notice: "Error unarchiving contest description", alert: true)
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
    params.require(:contest_description).permit(:created_by, :active, :archived, :eligibility_rules, :name, :notes, :short_name,
                                                :container_id, :status_id)
  end
end
