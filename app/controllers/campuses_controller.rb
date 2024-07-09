class CampusesController < ApplicationController
  before_action :set_campus, only: %i[show edit update destroy]

  def index
    @campuses = Campus.all
  end

  def show; end

  def new
    @campus = Campus.new
  end

  def edit; end

  def create
    @campus = Campus.new(campus_params)
    if @campus.save
      redirect_to @campus, notice: 'Campus was successfully created.'
    else
      render :new
    end
  end

  def update
    if @campus.update(campus_params)
      redirect_to @campus, notice: 'Campus was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @campus.destroy
    redirect_to campuses_url, notice: 'Campus was successfully destroyed.'
  end

  private

  def set_campus
    @campus = Campus.find(params[:id])
  end

  def campus_params
    params.require(:campus).permit(:campus_descr, :campus_cd)
  end
end
