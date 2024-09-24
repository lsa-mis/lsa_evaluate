class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Default to deny access; override in specific policies
  def index?
    false
  end

  def show?
    false
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

  def axis_mundi?
    user&.axis_mundi? || false
  end
  # Scope class for determining accessible records
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if axis_mundi?
        scope.all
      else
        scope.none
      end
    end

    private

    def axis_mundi?
      user&.axis_mundi? || false
    end
  end
end
