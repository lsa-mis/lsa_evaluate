class EntryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if admin_user?
        scope.all
      else
        scope.where(profile: user.profile)
      end
    end
  end

  def show?
    admin_user? || record.profile.user == user
  end

  def create?
    admin_user? || (record.profile.user == user && record.contest_instance.open?)
  end

  def update?
    admin_user? || (record.profile.user == user && record.contest_instance.open?)
  end

  # def destroy?
  #   admin_user? || (record.profile.user == user && record.contest_instance.open?)
  # end

  def soft_delete?
    admin_user? || (record.profile.user == user && record.contest_instance.open?)
  end

  def toggle_disqualified?
    admin_user? || user.has_container_role?(record.contest_instance.contest_description.container)
  end
end
