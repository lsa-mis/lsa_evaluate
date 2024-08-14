class AssignmentsController < ApplicationController
  before_action :set_container

  def create
    # @container = Container.find(params[:container_id])
    @assignment = @container.assignments.build(assignment_params)

    if @assignment.save
      @assignments = @container.assignments.includes(:user, :role)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @container, notice: 'Assignment was successfully created.' }
      end
    else
      render :new
    end
  end

  def destroy
    @assignment = @container.assignments.find(params[:id])
    @assignment.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @container, notice: 'Assignment was successfully removed.' }
    end
  end

  private

  def set_container
    @container = Container.find(params[:container_id])
  end

  def assignment_params
    params.require(:assignment).permit(:user_id, :role_id)
  end
end
