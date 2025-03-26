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

  def manage?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def update_rankings?
    return false unless user && record
    return false unless record.judging_open?
    record.judges.include?(user)
  end

  def finalize_rankings?
    return false unless user && record
    return false unless record.judging_open?
    record.judges.include?(user)
  end

  def complete?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def uncomplete?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def activate?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def deactivate?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end

  def send_round_results?
    user&.has_container_role?(record.contest_description.container) || axis_mundi?
  end
end
