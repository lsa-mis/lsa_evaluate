class ContainerPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if axis_mundi?
        scope.all
      else
        scope.where(id: user&.containers.select(:id))
      end
    end
  end

  def index?
    user&.containers.exists? || axis_mundi?
  end

  def show?
    user&.has_container_role?(record) || axis_mundi?
  end

  def create?
    user&.is_employee? || axis_mundi?
  end

  def update?
    user&.has_container_role?(record) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record) || axis_mundi?
  end
end
