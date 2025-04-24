class UserRolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def show?
    record.user == user || axis_mundi?
  end

  def create?
    axis_mundi?
  end

  def update?
    axis_mundi?
  end

  def destroy?
    axis_mundi?
  end
end
