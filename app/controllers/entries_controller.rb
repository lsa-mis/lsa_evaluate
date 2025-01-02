class EntriesController < ApplicationController
  include AvailableContestsConcern
  before_action :set_entry, only: %i[ show edit update destroy soft_delete toggle_disqualified applicant_profile ]
  before_action :authorize_entry, only: %i[show edit update destroy]
  before_action :authorize_index, only: [ :index ]

  # GET /entries or /entries.json
  def index
    # @entries = Entry.all
    @entries = policy_scope(Entry)
  end

  # GET /entries/1 or /entries/1.json
  def show
    authorize @entry
  end

  # GET /entries/new
  def new
    contest_instance_id = params[:contest_instance_id]
    @entry = Entry.new(
      contest_instance_id: contest_instance_id,
      profile: current_user.profile
    )
    authorize @entry
  end

  # GET /entries/1/edit
  def edit
    # @entry = Entry.find(params[:id])
    authorize @entry
  end

  def create
    @entry = current_user.profile.entries.build(entry_params)
    authorize @entry
    if @entry.save
      # Simulate a delay (remove in production)
      # sleep(3)

      save_pen_name = ActiveModel::Type::Boolean.new.cast(@entry.save_pen_name_to_profile)
      if save_pen_name && current_user.profile.pen_name.blank?
        current_user.profile.update(pen_name: @entry.pen_name)
      end

      redirect_to applicant_dashboard_path, notice: 'Entry was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entries/1 or /entries/1.json
  def update
    authorize @entry
    respond_to do |format|
      if @entry.update(entry_params)
        format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /entries/1 or /entries/1.json
  def destroy
    authorize @entry
    @entry.destroy!

    respond_to do |format|
      format.html { redirect_to entries_url, notice: 'Entry was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def soft_delete
    authorize @entry, :soft_delete?
    if @entry.soft_deletable?
      if @entry.update(deleted: true)
        @profile = current_user.profile
        @entries = Entry.active.where(profile: @profile)
        available_contests

        flash.now[:notice] = 'Entry was successfully removed.'
        respond_to do |format|
          format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully removed.' }
          format.turbo_stream
        end
      else
        flash.now[:alert] = 'Failed to remove entry.'
        respond_to do |format|
          format.html { redirect_to applicant_dashboard_path, alert: 'Failed to remove entry.' }
          format.turbo_stream
        end
      end
    else
      flash.now[:alert] = 'Cannot delete entry after contest has closed.'
      respond_to do |format|
        format.html { redirect_to applicant_dashboard_path, alert: 'Cannot delete entry after contest has closed.' }
        format.turbo_stream
      end
    end
  end

  def toggle_disqualified
    authorize @entry
    @entry.toggle!(:disqualified)
    redirect_to request.referer || root_path, notice: 'Entry disqualification status has been updated.'
  end

  def applicant_profile
    authorize @entry, :view_applicant_profile?
    @profile = @profile = @entry.profile
    @entries = Entry.active.where(profile: @profile)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params[:id])
    end

    def authorize_entry
      authorize @entry
    end

    def authorize_index
      authorize Entry
    end
    # Only allow a list of trusted parameters through.
    def entry_params
      params.require(:entry).permit(:title, :disqualified, :deleted, :contest_instance_id,
                                    :profile_id, :category_id, :entry_file, :pen_name,
                                    :save_pen_name_to_profile, :campus_employee, :accepted_financial_aid_notice,
                                    :receiving_financial_aid, :financial_aid_description)
    end
end
