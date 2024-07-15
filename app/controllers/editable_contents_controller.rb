class EditableContentsController < ApplicationController
  before_action :set_editable_content, only: %i[show edit update destroy]
  before_action :authorize_editing, only: %i[edit update]

  def index
    @editable_contents = EditableContent.all
  end

  def show
    @editable_content = EditableContent.find(params[:id])
  end

  def new
    @editable_content = EditableContent.new
  end

  def edit; end

  def create
    @editable_content = EditableContent.new(editable_content_params)

    respond_to do |format|
      if @editable_content.save
        format.html { redirect_to @editable_content, notice: 'Content was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @editable_content.update(editable_content_params)
        format.html { redirect_to @editable_content, notice: 'Content was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @editable_content.destroy

    respond_to do |format|
      format.html { redirect_to editable_contents_url, notice: 'Content was successfully destroyed.' }
    end
  end

  private

  def set_editable_content
    @editable_content = EditableContent.find(params[:id])
  end

  def authorize_editing
    return if current_user.editable_content_administrator?

    redirect_to root_path, alert: 'You are not authorized to edit this content.'
  end

  def editable_content_params
    params.require(:editable_content).permit(:page, :section, :content)
  end
end
