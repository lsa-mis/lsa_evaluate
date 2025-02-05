class UsersDashboardPolicy < ApplicationPolicy
  def index?
    axis_mundi?
  end

  def show?
    axis_mundi?
  end

  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.none
      end
    end
  end
end
