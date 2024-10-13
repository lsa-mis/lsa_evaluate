class ProfilePolicy < ApplicationPolicy
  def index?
    axis_mundi?
  end

  def new?
    !user_has_persisted_profile? || axis_mundi?
  end

  def create?
    !user_has_persisted_profile? || axis_mundi?
  end

  def show?
    user_is_owner? || axis_mundi?
  end

  def update?
    user_is_owner? || axis_mundi?
  end

  def destroy?
    user_is_owner? || axis_mundi?
  end

  private

  def user_is_owner?
    user && record && record.user_id == user.id
  end

  def user_has_persisted_profile?
    user&.profile&.persisted?
  end
end
