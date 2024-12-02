class ContestInstancePolicy < ApplicationPolicy
  def index?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def show?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def create?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def update?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def manage_judges?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def view_judging_results?
    return true if user&.axis_mundi?
    return true if user&.has_container_role?(record.contest_description.container)
    return true if record.judges.include?(user) && record.judge_evaluations_complete?
    false
  end
end
