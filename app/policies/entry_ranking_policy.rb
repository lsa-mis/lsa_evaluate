class EntryRankingPolicy < ApplicationPolicy
  def create?
    return false unless user&.judge? || axis_mundi?
    
    assignment = JudgingAssignment.find_by(
      user: user,
      contest_instance: record.judging_round.contest_instance,
      active: true
    )
    
    # Also check if they're assigned to this specific round
    round_assignment = RoundJudgeAssignment.find_by(
      user: user,
      judging_round: record.judging_round,
      active: true
    )
    
    (assignment.present? && round_assignment.present?) || axis_mundi?
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
        # Only show rankings for contests they're assigned to
        contest_instances = user.judging_assignments.active.pluck(:contest_instance_id)
        scope.joins(judging_round: :contest_instance)
             .where(judging_rounds: { contest_instance_id: contest_instances })
             .where(user: user)
      else
        scope.none
      end
    end
  end
end
