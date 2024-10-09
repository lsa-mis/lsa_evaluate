# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Default to check axis_mundi? for all actions
  def index?
    axis_mundi?
  end

  def show?
    axis_mundi?
  end

  def create?
    axis_mundi?
  end

  def new?
    create?
  end

  def update?
    axis_mundi?
  end

  def edit?
    update?
  end

  def destroy?
    axis_mundi?
  end

  # Common method to check for Axis mundi role
  def axis_mundi?
    user&.axis_mundi? || false
  end

  # Default Scope
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.axis_mundi?
        scope.all
      else
        scope.none
      end
    end
  end
end
