# frozen_string_literal: true

class CategoryPolicy < ApplicationPolicy
  def index?
    manage?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  private

  def manage?
    user&.has_container_role?(record.container) || axis_mundi?
  end
end
