class JudgeDashboardPolicy < ApplicationPolicy
  def index?
    user&.judge?
  end
end
