class ContestInstancePolicy < ApplicationPolicy
  def index?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def show?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def create?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def update?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end
end
