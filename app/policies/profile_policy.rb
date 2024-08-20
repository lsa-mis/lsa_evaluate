class ProfilePolicy < ApplicationPolicy
  def index?
    user_is_owner? || admin_user?
  end

  def new?
    Rails.logger.debug { "&&!&&!&&!&&! Checking new? for user #{user.id}: has profile? #{user_has_persisted_profile?}, is admin? #{admin_user?}" }
    !user_has_persisted_profile? || admin_user?
  end

  def create?
    !user_has_persisted_profile? || admin_user?
  end

  def show?
    (user_has_persisted_profile? && user_is_owner?) || admin_user?
  end

  def update?
    (user_has_persisted_profile? && user_is_owner?) || admin_user?
  end

  def destroy?
    (user_has_persisted_profile? && user_is_owner?) || admin_user?
  end

  private

  def user_is_owner?
    record.present? && record.user_id == user.id
  end

  def user_has_persisted_profile?
    Rails.logger.debug { "@@@@@@@@@ user has profile? #{user.profile&.persisted?}" }
    user.profile&.persisted?
  end
end
