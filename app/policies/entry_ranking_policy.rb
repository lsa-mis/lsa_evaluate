class EntryRankingPolicy < ApplicationPolicy
  def create?
    return false unless user&.judge?
    assignment = JudgingAssignment.find_by(
      user: user,
      contest_instance: record.judging_round.contest_instance,
      active: true
    )
    assignment.present? || axis_mundi?
  end

  def update?
    record.user == user || axis_mundi?
  end

  def show?
    record.user == user || 
    user&.has_container_role?(record.judging_round.contest_instance.contest_description.container) || 
    axis_mundi?
  end

  class Scope < Scope
    def resolve
      if user.axis_mundi?
        scope.all
      elsif user.judge?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
