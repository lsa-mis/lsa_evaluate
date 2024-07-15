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

    respond_to do |format|
      if @class_level.save
        format.html { redirect_to @class_level, notice: 'Class Level was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @class_level.update(class_level_params)
        format.html { redirect_to @class_level, notice: 'Class Level was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @class_level.destroy

    respond_to do |format|
      format.html { redirect_to class_levels_url, notice: 'Class Level was successfully destroyed.' }
    end
  end

  private

  def set_class_level
    @class_level = ClassLevel.find(params[:id])
  end

  def class_level_params
    params.require(:class_level).permit(:name, :description)
  end
end
