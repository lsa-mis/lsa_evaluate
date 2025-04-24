class JudgingAssignmentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.where(user: user)
             .or(scope.joins(contest_instance: { contest_description: :container })
                      .where(containers: { id: user&.containers&.pluck(:id) || [] }))
      end
    end
  end

  def create?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def show?
    record.user == user ||
    user&.has_container_role?(record.contest_instance.contest_description.container) ||
    axis_mundi?
  end
end
