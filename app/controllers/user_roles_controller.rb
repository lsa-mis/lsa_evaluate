# app/controllers/user_roles_controller.rb
class UserRolesController < ApplicationController
  before_action :set_user_role, only: %i[show edit update destroy]

  def index
    @user_roles = UserRole.all
  end

  def show; end

  def new
    @user_role = UserRole.new
  end

  def edit; end

  def create
    @user_role = UserRole.new(user_role_params)

    respond_to do |format|
      if @user_role.save
        format.html { redirect_to @user_role, notice: 'UserRole was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @user_role.update(user_role_params)
        format.html { redirect_to @user_role, notice: 'UserRole was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @user_role.destroy
    respond_to do |format|
      format.html { redirect_to user_roles_url, notice: 'UserRole was successfully destroyed.' }
    end
  end

  private

  def set_user_role
    @user_role = UserRole.find(params[:id])
  end

  def user_role_params
    params.require(:user_role).permit(:user_id, :role_id)
  end
end
