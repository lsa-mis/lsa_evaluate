class SchoolsController < ApplicationController
  before_action :set_school, only: %i[show edit update destroy]

  def index
    authorize School
    @schools = policy_scope(School)
  end

  def show
    authorize @school
  end

  def new
    @school = School.new
    authorize @school
  end

  def edit
    authorize @school
  end

  def create
    @school = School.new(school_params)
    authorize @school

    respond_to do |format|
      if @school.save
        format.html { redirect_to @school, notice: 'School was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @school
    respond_to do |format|
      if @school.update(school_params)
        format.html { redirect_to @school, notice: 'School was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @school
    @school.destroy

    respond_to do |format|
      format.html { redirect_to schools_url, notice: 'School was successfully destroyed.' }
    end
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def school_params
    params.require(:school).permit(:name)
  end
end
