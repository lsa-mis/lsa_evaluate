class JudgingAssignmentPolicy < ApplicationPolicy
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
