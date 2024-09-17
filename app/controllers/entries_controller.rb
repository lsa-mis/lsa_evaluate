class EntriesController < ApplicationController
  before_action :set_entry, only: %i[ show edit update destroy soft_delete ]
  before_action :authorize_entry, only: %i[ soft_delete ]

  # GET /entries or /entries.json
  def index
    @entries = Entry.all
  end

  # GET /entries/1 or /entries/1.json
  def show
  end

  # GET /entries/new
  def new
    contest_instance_id = params[:contest_instance_id]
    @entry = Entry.new(
      contest_instance_id: contest_instance_id,
      profile: current_user.profile
    )
  end

  # GET /entries/1/edit
  def edit
    @entry = Entry.find(params[:id])
  end

  # POST /entries or /entries.json
  def create
    @entry = Entry.new(entry_params)

    respond_to do |format|
      if @entry.save
        format.html { redirect_to entry_url(@entry), notice: 'Entry was successfully created.' }
        format.json { render :show, status: :created, location: @entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /entries/1 or /entries/1.json
  def update
    respond_to do |format|
      if @entry.update(entry_params)
        format.html { redirect_to entry_url(@entry), notice: 'Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /entries/1 or /entries/1.json
  def destroy
    @entry.destroy!

    respond_to do |format|
      format.html { redirect_to entries_url, notice: 'Entry was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def soft_delete
    if @entry.update(deleted: true)
      respond_to do |format|
        format.html { redirect_to applicant_dashboard_path, notice: 'Entry was successfully removed.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to applicant_dashboard_path, alert: 'Failed to remove entry.' }
        format.turbo_stream
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params[:id])
    end

    def authorize_entry
      # Ensure the current user owns the entry
      unless @entry.profile.user == current_user
        redirect_to root_path, alert: 'You are not authorized to perform this action.'
      end
    end

    # Only allow a list of trusted parameters through.
    def entry_params
      params.require(:entry).permit(:title, :disqualified, :deleted, :contest_instance_id, :profile_id, :category_id, :entry_file)
    end
end
