class UserRolePolicy < ApplicationPolicy
  def index?
    admin_user?
  end

  def show?
    admin_user?
  end

  def create?
    admin_user?
  end

  def new?
    create?
  end

  def update?
    admin_user?
  end

  def edit?
    update?
  end

  def destroy?
    admin_user?
  end

  class Scope < Scope
    def resolve
      if admin_user?
        scope.all
      else
        scope.none
      end
    end
  end
end
