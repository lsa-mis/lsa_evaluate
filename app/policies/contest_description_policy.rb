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
end
