# app/policies/entry_policy.rb
class EntryPolicy < ApplicationPolicy
  # Scope class remains as generated
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin_user?
        scope.all
      else
        scope.where(profile: user.profile)
      end
    end
  end

  def soft_delete?
    record.contest_instance.open? && record.profile.user == user
  end

  def toggle_disqualified?
    user.has_container_role?(record.contest_instance.contest_description.container)
  end
end
