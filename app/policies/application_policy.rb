class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.exists?(id: record.id)
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def admin_user?
    user.user_roles.joins(:role).exists?(roles: { kind: 'Axis Mundi' })
  end

  # Override the `authorize` method to allow admin users
  def authorized_action?
    admin_user? || specific_action?
  end

  private

  # Implement specific action rules in derived policies
  def specific_action?
    false
  end
end
