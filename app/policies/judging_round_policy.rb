class JudgingRoundPolicy < ApplicationPolicy
  def show?
    user&.has_container_role?(record.contest_instance.contest_description.container) || 
    record.contest_instance.judges.include?(user) ||
    axis_mundi?
  end

  def create?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def update?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def destroy?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def complete_round?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def select_entries_for_next_round?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end
end
