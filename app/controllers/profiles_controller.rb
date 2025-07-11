# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[show edit update destroy]
  before_action :authorize_profile, only: %i[show edit update destroy]

  # GET /profiles
  def index
    if current_user.axis_mundi?
      @profiles = policy_scope(Profile)
      authorize Profile
    else
      if current_user.profile&.persisted?
        redirect_to current_user.profile
      else
        redirect_to new_profile_path
      end
    end
  end

  # GET /profiles/1
  def show; end

  # GET /profiles/new
  def new
    @profile = current_user.build_profile
    if @profile.nil?
      Rails.logger.debug { "^^^^^^^^^^^^^^^^ Profile is nil for user: #{current_user.inspect}" }
    else
      authorize @profile
    end
  end

  # GET /profiles/1/edit
  def edit; end

  # POST /profiles
  def create
    @profile = current_user.build_profile(profile_params)
    authorize @profile

    respond_to do |format|
      if @profile.save
        format.html { redirect_to applicant_dashboard_path, notice: 'Profile was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profiles/1
  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to applicant_dashboard_path, notice: 'Profile was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1
  def destroy
    @profile.destroy

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'Profile was successfully destroyed.' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_profile
    @profile = Profile.find(params[:id])
  end

  def authorize_profile
    authorize @profile
  end
  # Only allow a list of trusted parameters through.
  def profile_params
    params.require(:profile).permit(:user_id, :umid, :preferred_first_name, :preferred_last_name, :class_level_id, :school_id, :campus_id,
                                    :major,
                                    :department, :grad_date, :degree, :receiving_financial_aid,
                                    :accepted_financial_aid_notice, :financial_aid_description,
                                    :hometown_publication, :pen_name)
  end
end
