class ContestDescriptionPolicy < ApplicationPolicy
  def index?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def show?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def create?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def update?
    user&.has_container_role?(record.container) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record.container) || axis_mundi?
  end
end
