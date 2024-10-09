# app/policies/container_policy.rb
class ContainerPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.where(id: user_containers_ids)
      end
    end

    private

    def user_containers_ids
      user&.containers&.pluck(:id) || []
    end
  end

  def index?
    user_has_containers? || axis_mundi?
  end

  def show?
    owns_container? || axis_mundi?
  end

  def create?
    user_is_employee? || axis_mundi?
  end

  def update?
    owns_container? || axis_mundi?
  end

  def destroy?
    owns_container? || axis_mundi?
  end

  private

  def user_has_containers?
    user&.containers&.exists?
  end

  def owns_container?
    user&.has_container_role?(record)
  end

  def user_is_employee?
    user&.is_employee?
  end
end
