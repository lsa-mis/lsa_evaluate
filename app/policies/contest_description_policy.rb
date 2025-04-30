class ContestDescriptionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def new?
    create?
  end

  def update?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def edit?
    update?
  end

  def destroy?
    axis_mundi?
  end

  def eligibility_rules?
    true
  end

  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      elsif user&.judge?
        # For judges, scope to contest_descriptions they're assigned to judge
        scope.joins(contest_instances: :judging_assignments)
             .where(contest_instances: { judging_assignments: { user_id: user.id, active: true } })
             .distinct
      else
        # For users with container roles, scope to their containers
        container_ids = user&.containers&.pluck(:id) || []
        scope.where(container_id: container_ids)
      end
    end
  end
end
