class JudgingAssignmentsController < ApplicationController
  before_action :set_contest_instance
  before_action :set_judging_assignment, only: [ :destroy ]
  before_action :authorize_contest_instance

  def index
    @judging_assignments = @contest_instance.judging_assignments.includes(:user)
    @available_judges = User.joins(:roles).where(roles: { kind: 'Judge' })
                          .where.not(id: @judging_assignments.pluck(:user_id))
  end

  def create
    @judging_assignment = @contest_instance.judging_assignments.build(judging_assignment_params)

    if @judging_assignment.save
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judge was successfully assigned.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: @judging_assignment.errors.full_messages.join(', ')
    end
  end

  def destroy
    @judging_assignment.destroy
    redirect_to container_contest_description_contest_instance_judging_assignments_path(
      @container, @contest_description, @contest_instance
    ), notice: 'Judge assignment was successfully removed.'
  end

  def create_judge
    authorize @contest_instance, :manage_judges?

    ActiveRecord::Base.transaction do
      # Transform email if not umich.edu
      email = params[:email]
      unless email.downcase.end_with?('@umich.edu')
        local_part, domain = email.split('@')
        email = "#{local_part}+#{domain}@umich.edu"
      end

      # Create the user
      @user = User.new(
        email: email,
        first_name: params[:first_name],
        last_name: params[:last_name],
        password: SecureRandom.hex(10)  # Random password as they'll use SSO
      )

      if @user.save
        # Assign Judge role
        judge_role = Role.find_by(kind: 'Judge')
        @user.roles << judge_role if judge_role

        # Create judging assignment
        @judging_assignment = @contest_instance.judging_assignments.build(user: @user)

        if @judging_assignment.save
          redirect_to container_contest_description_contest_instance_judging_assignments_path(
            @container, @contest_description, @contest_instance
          ), notice: 'New judge was successfully created and assigned'
        else
          raise ActiveRecord::Rollback
          redirect_to container_contest_description_contest_instance_judging_assignments_path(
            @container, @contest_description, @contest_instance
          ), alert: @judging_assignment.errors.full_messages.join(', ')
        end
      else
        redirect_to container_contest_description_contest_instance_judging_assignments_path(
          @container, @contest_description, @contest_instance
        ), alert: @user.errors.full_messages.join(', ')
      end
    end
  rescue => e
    redirect_to container_contest_description_contest_instance_judging_assignments_path(
      @container, @contest_description, @contest_instance
    ), alert: 'An error occurred while creating the judge.'
  end

  private

  def set_contest_instance
    @container = Container.find(params[:container_id])
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
  end

  def set_judging_assignment
    @judging_assignment = @contest_instance.judging_assignments.find(params[:id])
  end

  def authorize_contest_instance
    authorize @contest_instance, :manage_judges?
  end

  def judging_assignment_params
    params.require(:judging_assignment).permit(:user_id, :active)
  end
end
