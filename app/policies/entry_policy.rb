class EntryPolicy < ApplicationPolicy
  def show?
    record.profile.user == user || axis_mundi?
  end

  def create?
    (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  end

  def update?
    (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  end

  # def destroy?
  #   (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  # end

  def soft_delete?
    (record.profile.user == user && record.contest_instance.open?) || axis_mundi?
  end

  def toggle_disqualified?
    user&.has_container_role?(record.contest_instance.contest_description.container) || axis_mundi?
  end
end
