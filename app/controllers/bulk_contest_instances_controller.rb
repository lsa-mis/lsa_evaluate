class BulkContestInstancesController < ApplicationController
  before_action :set_container
  before_action :authorize_container_access

  def new
    @contest_descriptions = @container.contest_descriptions
                                    .joins(:contest_instances)
                                    .distinct
    @bulk_contest_instance = BulkContestInstanceForm.new
  end

  def create
    @bulk_contest_instance = BulkContestInstanceForm.new(
      date_open: params[:bulk_contest_instance_form][:date_open],
      date_closed: params[:bulk_contest_instance_form][:date_closed]
    )

    if @bulk_contest_instance.date_open.blank? || @bulk_contest_instance.date_closed.blank?
      setup_error_for_missing_dates
      return render :new, status: :unprocessable_entity
    end

    if Date.parse(@bulk_contest_instance.date_closed) < Date.parse(@bulk_contest_instance.date_open)
      setup_error_for_invalid_dates
      return render :new, status: :unprocessable_entity
    end

    success = create_contest_instances

    if success
      redirect_to container_path(@container), notice: 'Contest instances were successfully created.'
    else
      setup_error_for_failed_creation
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def authorize_container_access
    authorize @container, :access_contest_instances?
  end

  def create_contest_instances
    success = true
    description_ids = params[:contest_description_ids]&.keys || []
    selected_descriptions = @container.contest_descriptions.where(id: description_ids)

    ActiveRecord::Base.transaction do
      selected_descriptions.each do |description|
        last_instance = description.contest_instances.order(created_at: :desc).first

        if last_instance
          # Create from existing instance
          new_instance = last_instance.dup
        else
          # Create new instance with default values
          new_instance = description.contest_instances.new(
            maximum_number_entries_per_applicant: 1,
            judging_rounds: 1,
            created_by: current_user.email
          )
        end

        # Set common attributes
        new_instance.date_open = params[:bulk_contest_instance_form][:date_open]
        new_instance.date_closed = params[:bulk_contest_instance_form][:date_closed]
        new_instance.created_by = current_user.email
        new_instance.active = false
        new_instance.archived = false

        # Copy relationships if they exist
        if last_instance
          new_instance.category_ids = last_instance.category_ids
          new_instance.class_level_ids = last_instance.class_level_ids
        end

        unless new_instance.save
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end
    success
  end

  def setup_error_for_missing_dates
    @contest_descriptions = @container.contest_descriptions.joins(:contest_instances).distinct
    flash.now[:alert] = []
    flash.now[:alert] << "Date open can't be blank" if @bulk_contest_instance.date_open.blank?
    flash.now[:alert] << "Date closed can't be blank" if @bulk_contest_instance.date_closed.blank?
  end

  def setup_error_for_invalid_dates
    @contest_descriptions = @container.contest_descriptions.joins(:contest_instances).distinct
    flash.now[:alert] = 'Date closed must be after date contest opens'
  end

  def setup_error_for_failed_creation
    @contest_descriptions = @container.contest_descriptions.joins(:contest_instances).distinct
    flash.now[:alert] = 'There was an error creating the contest instances.'
  end
end
