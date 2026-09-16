# frozen_string_literal: true

class EntryAwardPolicy < ApplicationPolicy
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
    container = record.entry.contest_instance.contest_description.container
    user&.has_container_role?(container) || axis_mundi?
  end
end
