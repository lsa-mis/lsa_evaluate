class EditableContentsController < ApplicationController
  before_action :set_editable_content, only: %i[show edit update destroy]
  before_action :authorize_editing, only: %i[edit update]

  def index
    @editable_contents = EditableContent.all
  end

  # GET /editable_contents/1 or /editable_contents/1.json
  def show
    @editable_content = EditableContent.find(params[:id])
  end

  # GET /editable_contents/new
  def new
    @editable_content = EditableContent.new
  end

  # GET /editable_contents/1/edit
  def edit; end

  # POST /editable_contents or /editable_contents.json
  def create
    @editable_content = EditableContent.new(editable_content_params)
    if @editable_content.save
      redirect_to @editable_content, notice: 'Content was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /editable_contents/1 or /editable_contents/1.json
  def update
    if @editable_content.update(editable_content_params)
      redirect_to @editable_content, notice: 'Content was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /editable_contents/1 or /editable_contents/1.json
  def destroy
    @editable_content.destroy
    redirect_to editable_contents_url, notice: 'Content was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_editable_content
    @editable_content = EditableContent.find(params[:id])
  end

  def authorize_editing
    return if current_user.editable_content_administrator?

    redirect_to root_path, alert: 'You are not authorized to edit this content.'
  end

  # Only allow a list of trusted parameters through.
  def editable_content_params
    params.require(:editable_content).permit(:page, :section, :content)
  end
end
