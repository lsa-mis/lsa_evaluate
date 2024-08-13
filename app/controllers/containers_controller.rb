class ContainersController < ApplicationController
  before_action :set_container, only: %i[show edit update destroy]

  def index
    @containers = Container.includes(:contest_descriptions).all
  end

  def show
    @assignments = @container.assignments.includes(:user, :role)
  end

  def new
    @container = Container.new
  end

  def edit; end

  def create
    @container = Container.new(container_params)
    @container.creator = current_user
    respond_to do |format|
      if @container.save
        format.html { redirect_to container_url(@container), notice: 'Container was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @container.update(container_params)
        format.html { redirect_to container_url(@container), notice: 'Container was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @container.destroy!
    respond_to do |format|
      format.html { redirect_to containers_url, notice: 'Container was successfully destroyed.' }
    end
  end

  def admin_content
    render 'admin_content'
  end

  private

  def set_container
    @container = Container.find(params[:id])
  end

  def container_params
    params.require(:container).permit(:name, :description, :department_id, :visibility_id,
                                      assignments_attributes: %i[id user_id role_id _destroy])
  end
end
