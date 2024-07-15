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

    respond_to do |format|
      if @campus.save
        format.html { redirect_to @campus, notice: 'Campus was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @campus.update(campus_params)
        format.html { redirect_to @campus, notice: 'Campus was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @campus.destroy

    respond_to do |format|
      format.html { redirect_to campuses_url, notice: 'Campus was successfully destroyed.' }
    end
  end

  private

  def set_campus
    @campus = Campus.find(params[:id])
  end

  def campus_params
    params.require(:campus).permit(:campus_descr, :campus_cd)
  end
end
