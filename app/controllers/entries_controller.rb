class EntriesController < ApplicationController
  before_action :set_entry, only: %i[ show edit update destroy soft_delete toggle_disqualified ]

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

  # POST /entries or /entries.json
  def create
    @entry = Entry.new(entry_params)
    authorize @entry
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
    authorize @entry
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
        format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash_messages', locals: { alert: 'Cannot delete entry after contest has closed.' }) }
      end
    end
  end

  def toggle_disqualified
    authorize @entry, :toggle_disqualified?
    @entry.disqualified = !@entry.disqualified
    if @entry.save
      flash.now[:notice] = 'Entry status updated successfully.'
      respond_to do |format|
        format.html { redirect_to container_path(@entry.contest_instance.contest_description.container), notice: 'Entry status updated successfully.' }
        format.turbo_stream
      end
    else
      flash.now[:alert] = 'Failed to update entry status.'
      respond_to do |format|
        format.html { redirect_to container_path(@entry.contest_instance.contest_description.container), alert: 'Failed to update entry status.' }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash_messages', locals: { alert: 'Failed to update entry status.' }) }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def entry_params
      params.require(:entry).permit(:title, :disqualified, :deleted, :contest_instance_id, :profile_id, :category_id, :entry_file)
    end
end
