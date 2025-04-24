class EntryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        # Start with a base scope that includes the necessary joins
        base_scope = scope.joins(contest_instance: { contest_description: :container })

        # Build the two conditions
        own_entries = base_scope.where(profile: user&.profile)
        container_entries = base_scope.where(containers: { id: user&.containers&.pluck(:id) || [] })

        # Combine them with OR
        own_entries.or(container_entries)
      end
    end
  end

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
