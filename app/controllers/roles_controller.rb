# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :set_role, only: %i[show edit update destroy]

  def index
    @roles = Role.all
  end

  def show; end

  def new
    @role = Role.new
  end

  def edit; end

  def create
    @role = Role.new(role_params)

    respond_to do |format|
      if @role.save
        format.html { redirect_to role_url(@role), notice: 'Role was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @role.update(role_params)
        format.html { redirect_to role_url(@role), notice: 'Role was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @role.destroy!

    respond_to do |format|
      format.html { redirect_to roles_url, notice: 'Role was successfully destroyed.' }
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:kind, :description)
  end
end
