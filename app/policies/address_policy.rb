# app/policies/address_policy.rb
class AddressPolicy < ApplicationPolicy
  def index?
    axis_mundi?
  end

  def show?
    axis_mundi? || owner?
  end

  def create?
    axis_mundi? || owner?
  end

  def new?
    create?
  end

  def update?
    axis_mundi? || owner?
  end

  def edit?
    update?
  end

  def destroy?
    axis_mundi?
  end

  private

  # Checks if the user owns the address via their profile
  def owner?
    user && (
      record == user.profile&.home_address ||
      record == user.profile&.campus_address
    )
  end

  class Scope < Scope
    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.none
      end
    end
  end
end
