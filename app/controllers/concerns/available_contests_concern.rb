module AvailableContestsConcern
  extend ActiveSupport::Concern

  private

  def available_contests
    @active_contests = ContestInstance.active_and_open
                                      .for_class_level(@profile.class_level_id)
                                      .with_public_visibility
                                      .available_for_profile(@profile)
                                      .includes(contest_description: { container: :visibility })
                                      .order('containers.name ASC')
                                      .distinct

    # Apply filtering if container_id is provided
    if params[:container_id].present?
      @active_contests = @active_contests.where(contest_descriptions: { container_id: params[:container_id] })
    end

    if params[:department_id].present?
      @active_contests = @active_contests.joins(contest_description: :container)
                                         .where(containers: { department_id: params[:department_id] })
    end

    # Update @active_contests_by_container after filtering
    @active_contests_by_container = @active_contests.group_by do |contest|
      contest.contest_description.container
    end
  end
end
