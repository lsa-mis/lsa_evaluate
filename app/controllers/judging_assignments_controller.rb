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

    # Validate required parameters
    if params[:email].blank? || params[:first_name].blank? || params[:last_name].blank?
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Email, first name, and last name are required.'
      return
    end

    # Validate email format
    unless params[:email] =~ URI::MailTo::EMAIL_REGEXP
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Please enter a valid email address.'
      return
    end

    # Transform email if not umich.edu
    original_email = params[:email].downcase
    transformed_email = if original_email.end_with?('@umich.edu')
      original_email
    else
      local_part, domain = original_email.split('@')
      "#{local_part}+#{domain}@umich.edu"
    end

    # Find or create the judge role
    judge_role = Role.find_by(kind: 'Judge')
    unless judge_role
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: 'Judge role not found'
      return
    end

    success = false
    error_message = nil

    ActiveRecord::Base.transaction do
      begin
        # Try to find existing user first
        @user = User.find_by(email: transformed_email)

        if @user
          # Add judge role if not already present
          @user.roles << judge_role unless @user.roles.include?(judge_role)
        else
          # Create new user if not found
          @user = User.new(
            email: transformed_email,
            first_name: params[:first_name],
            last_name: params[:last_name],
            password: SecureRandom.hex(10),
            uniqname: transformed_email.split('@').first,
            display_name: "#{params[:first_name]} #{params[:last_name]}"
          )

          if @user.save
            @user.roles << judge_role
          else
            error_message = @user.errors.full_messages.join(', ')
            raise ActiveRecord::Rollback
          end
        end

        # Create container role association if not exists
        unless Assignment.exists?(user: @user, container: @container, role: judge_role)
          Assignment.create!(user: @user, container: @container, role: judge_role)
        end

        # Create judging assignment if not exists
        unless JudgingAssignment.exists?(user: @user, contest_instance: @contest_instance)
          @judging_assignment = @contest_instance.judging_assignments.build(user: @user)

          if @judging_assignment.save
            success = true
          else
            error_message = @judging_assignment.errors.full_messages.join(', ')
            raise ActiveRecord::Rollback
          end
        else
          success = true
        end
      rescue ActiveRecord::RecordInvalid => e
        error_message = e.record.errors.full_messages.join(', ')
        raise ActiveRecord::Rollback
      rescue => e
        error_message = e.message
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), notice: 'Judge was successfully created/updated and assigned.'
    else
      redirect_to container_contest_description_contest_instance_judging_assignments_path(
        @container, @contest_description, @contest_instance
      ), alert: error_message || 'An error occurred while creating/updating the judge.'
    end
  end

  def judge_lookup
    @container = Container.find(params[:container_id])
    @contest_description = ContestDescription.find(params[:contest_description_id])
    @contest_instance = ContestInstance.find(params[:contest_instance_id])

    assigned_ids = @contest_instance.judging_assignments.pluck(:user_id)
    query = params[:q].to_s.strip

    available_judges = User.joins(:roles)
      .where(roles: { kind: 'Judge' })
      .where.not(id: assigned_ids)
      .where('users.first_name LIKE :q OR users.last_name LIKE :q OR users.email LIKE :q', q: "%#{query}%")
      .limit(10)

    render json: available_judges.map { |u| { id: u.id, name: "#{u.first_name} #{u.last_name} (#{u.email})" } }
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
