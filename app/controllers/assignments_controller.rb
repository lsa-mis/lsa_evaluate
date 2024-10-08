class AssignmentsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_container

  def create
    @user = User.find_by(uid: assignment_params[:uid])

    if @user.nil?
      @assignment = @container.assignments.build
      @assignment.errors.add(:uid, 'User with this UID does not exist.')
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    else
      @assignment = @container.assignments.build(user: @user, role_id: assignment_params[:role_id])

      if @assignment.save
        @assignments = @container.assignments.includes(:user, :role)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @container, notice: 'Assignment was successfully created.' }
        end
      else
        respond_to do |format|
          format.turbo_stream { render :create, status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @assignment = @container.assignments.find(params[:id])
  
    if @assignment.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@assignment)) }
        format.html { redirect_to @container, notice: 'Assignment was successfully removed.' }
      end
    else
      respond_to do |format|
        # Replace the row content with the error message instead of removing it
        format.turbo_stream { render turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@assignment), partial: 'containers/assignment_row_with_error', locals: { assignment: @assignment, container: @container }) }
        format.html { redirect_to @container, alert: @assignment.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def set_container
    @container = Container.find(params[:container_id])
  end

  def assignment_params
    params.require(:assignment).permit(:uid, :role_id)
  end
end
