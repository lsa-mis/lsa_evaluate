class ContainerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    private

    def specific_scope
      scope.joins(:assignments).where(assignments: { user_id: user.id, role_id: [ container_admin_role.id, container_manager_role.id ] })
    end

    def container_admin_role
      @container_admin_role ||= Role.find_by(kind: 'Container Administrator')
    end

    def container_manager_role
      @container_manager_role ||= Role.find_by(kind: 'Container Manager')
    end
  end

  def index?
    user_has_assignment_role? || admin_user?
  end

  def show?
    user_has_assignment_role? || admin_user?
  end

  def create?
    user_is_employee? || admin_user?
  end

  def update?
    user_has_assignment_role? || admin_user?
  end

  def destroy?
    user_has_assignment_role? || admin_user?
  end

  private

  def user_has_assignment_role?
    record.assignments.exists?(user_id: user.id, role_id: [ container_admin_role.id, container_manager_role.id ])
  end

  def user_is_employee?
    user.person_affiliation == 'employee'
  end

  def container_admin_role
    Role.find_by(kind: 'Container Administrator')
  end

  def container_manager_role
    Role.find_by(kind: 'Container Manager')
  end
end
