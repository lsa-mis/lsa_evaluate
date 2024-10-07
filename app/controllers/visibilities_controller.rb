class VisibilitiesController < ApplicationController
  before_action :set_visibility, only: %i[show edit update destroy]

  def index
    authorize Visibility
    @visibilities = policy_scope(Visibility)
  end

  def show
    authorize @visibility
  end

  def new
    @visibility = Visibility.new
    authorize @visibility
  end

  def edit
    authorize @visibility
  end

  def create
    @visibility = Visibility.new(visibility_params)
    authorize @visibility

    respond_to do |format|
      if @visibility.save
        format.html { redirect_to visibility_url(@visibility), notice: 'Visibility was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @visibility
    respond_to do |format|
      if @visibility.update(visibility_params)
        format.html { redirect_to visibility_url(@visibility), notice: 'Visibility was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @visibility
    @visibility.destroy!

    respond_to do |format|
      format.html { redirect_to visibilities_url, notice: 'Visibility was successfully destroyed.' }
    end
  end

  private

  def set_visibility
    @visibility = Visibility.find(params[:id])
  end

  def visibility_params
    params.require(:visibility).permit(:kind, :description)
  end
end
