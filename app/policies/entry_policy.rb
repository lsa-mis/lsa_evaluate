class EntryPolicy < ApplicationPolicy
  def create?
    (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  end

  def soft_delete?
    (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  end

  def toggle_disqualified?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end

  def view_applicant_profile?
    record.profile.user == user ||
    user&.has_container_role?(record.contest_instance.contest_description.container) ||
    axis_mundi?
  end
end
