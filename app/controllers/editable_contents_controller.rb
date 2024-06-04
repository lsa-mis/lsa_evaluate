class EditableContentsController < ApplicationController
  before_action :set_editable_content, only: %i[show edit update destroy]

  # GET /editable_contents or /editable_contents.json
  def index
    @editable_contents = EditableContent.all
  end

  # GET /editable_contents/1 or /editable_contents/1.json
  def show
  end

  # GET /editable_contents/new
  def new
    @editable_content = EditableContent.new
  end

  # GET /editable_contents/1/edit
  def edit
  end

  # POST /editable_contents or /editable_contents.json
  def create
    @editable_content = EditableContent.new(editable_content_params)

    respond_to do |format|
      if @editable_content.save
        format.html do
          redirect_to editable_content_url(@editable_content), notice: 'editable_content was successfully created.'
        end
        format.json { render :show, status: :created, location: @editable_content }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @editable_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /editable_contents/1 or /editable_contents/1.json
  def update
    respond_to do |format|
      if @editable_content.update(editable_content_params)
        format.html do
          redirect_to editable_content_url(@editable_content), notice: 'editable_content was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @editable_content }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @editable_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /editable_contents/1 or /editable_contents/1.json
  def destroy
    @editable_content.destroy!

    respond_to do |format|
      format.html { redirect_to editable_contents_url, notice: 'editable_content was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_editable_content
    @editable_content = EditableContent.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def editable_content_params
    params.require(:editable_content).permit(:page, :section, :content)
  end
end
