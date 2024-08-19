class ContainerPolicy < ApplicationPolicy
  def create?
    user_is_employee? || admin_user?
  end

  def update?
    user_is_creator? || admin_user?
  end

  def destroy?
    user_is_creator? || admin_user?
  end

  private

  def user_is_creator?
    record.assignments.exists?(user: user)
  end

  def user_is_employee?
    user.person_affiliation == 'employee'
  end

  def admin_user?
    user.user_roles.joins(:role).exists?(roles: { kind: 'Axis Mundi' })
  end
end
