class DepartmentsController < ApplicationController
  before_action :set_department, only: %i[show edit update destroy]

  def index
    authorize Department
    @departments = policy_scope(Department)
  end

  def show
    authorize @department
  end

  def new
    @department = Department.new
    authorize @department
  end

  def edit
    authorize @department
  end

  def create
    @department = Department.new(department_params)
    authorize @department

    respond_to do |format|
      if @department.save
        format.html { redirect_to department_url(@department), notice: 'Department was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @department
    respond_to do |format|
      if @department.update(department_params)
        format.html { redirect_to department_url(@department), notice: 'Department was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @department
    @department.destroy!

    respond_to do |format|
      format.html { redirect_to departments_url, notice: 'Department was successfully destroyed.' }
    end
  end

  private

  def set_department
    @department = Department.find(params[:id])
  end

  def department_params
    params.require(:department).permit(:dept_id, :dept_description, :name)
  end
end
