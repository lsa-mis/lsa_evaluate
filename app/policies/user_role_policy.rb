class UserRolePolicy < ApplicationPolicy
  def index?
    axis_mundi?
  end

  def show?
    axis_mundi?
  end

  def create?
    axis_mundi?
  end

  def new?
    create?
  end

  def update?
    axis_mundi?
  end

  def edit?
    update?
  end

  def destroy?
    axis_mundi?
  end

  class Scope < Scope
    def resolve
      if axis_mundi?
        scope.all
      else
        scope.none
      end
    end
  end
end
