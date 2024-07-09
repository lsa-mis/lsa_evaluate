class ClassLevelsController < ApplicationController
  before_action :set_class_level, only: %i[show edit update destroy]

  def index
    @class_levels = ClassLevel.all
  end

  def show; end

  def new
    @class_level = ClassLevel.new
  end

  def edit; end

  def create
    @class_level = ClassLevel.new(class_level_params)
    if @class_level.save
      redirect_to @class_level, notice: 'Class Level was successfully created.'
    else
      render :new
    end
  end

  def update
    if @class_level.update(class_level_params)
      redirect_to @class_level, notice: 'Class Level was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @class_level.destroy
    redirect_to class_levels_url, notice: 'Class Level was successfully destroyed.'
  end

  private

  def set_class_level
    @class_level = ClassLevel.find(params[:id])
  end

  def class_level_params
    params.require(:class_level).permit(:name, :description)
  end
end
