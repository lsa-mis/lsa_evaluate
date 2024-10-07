class RolesController < ApplicationController
  before_action :set_role, only: %i[show edit update destroy]

  # GET /roles
  def index
    authorize Role
    @roles = policy_scope(Role)
  end

  # GET /roles/1
  def show
    authorize @role
  end

  # GET /roles/new
  def new
    @role = Role.new
    authorize @role
  end

  # GET /roles/1/edit
  def edit
    authorize @role
  end

  # POST /roles
  def create
    @role = Role.new(role_params)
    authorize @role
    if @role.save
      redirect_to @role, notice: 'Role was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/1
  def update
    authorize @role
    if @role.update(role_params)
      redirect_to @role, notice: 'Role was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /roles/1
  def destroy
    authorize @role
    @role.destroy!
    redirect_to roles_url, notice: 'Role was successfully destroyed.'
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:kind, :description)
  end
end
