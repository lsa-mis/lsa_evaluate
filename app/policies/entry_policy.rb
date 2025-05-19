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
    container = record.contest_instance.contest_description.container
    record.profile.user == user ||
    user&.has_container_role?(container, ['Collection Administrator', 'Collection Manager']) ||
    axis_mundi?
  end

  def show?
    # Allow users to see their own entries
    return true if record.profile.user == user

    # Allow collection admins/managers to see entries from their containers
    container = record.contest_instance.contest_description.container
    return true if user&.has_container_role?(container)

    # Allow judges to see entries they've been assigned to judge
    judged_contest_instance_ids = user.judging_assignments.pluck(:contest_instance_id)
    return true if judged_contest_instance_ids.include?(record.contest_instance_id)

    # Fall back to axis_mundi check
    axis_mundi?
  end

  class Scope < Scope
    def resolve
      base_scope = scope.where(deleted: false) # Only show non-deleted entries by default

      if user.nil?
        scope.none
      elsif user.axis_mundi?
        # Axis mundi can see all entries
        base_scope
      elsif user.administrator? || user.manager?
        # Collection administrators and managers can see entries from their containers
        admin_role_ids = Role.where(kind: ['Collection Administrator', 'Collection Manager']).pluck(:id)
        admin_container_ids = user.assignments
                                  .where(role_id: admin_role_ids)
                                  .pluck(:container_id)

        base_scope.joins(contest_instance: { contest_description: :container })
                 .where(containers: { id: admin_container_ids })
      elsif user.judge?
        # Judges can only see entries they've been assigned to judge
        judged_contest_instance_ids = user.judging_assignments.pluck(:contest_instance_id)
        base_scope.where(contest_instance_id: judged_contest_instance_ids)
      elsif user.profile.present?
        # Regular users can only see their own entries
        base_scope.where(profile: user.profile)
      else
        # User without a profile can't see any entries
        scope.none
      end
    end
  end
end
