# frozen_string_literal: true

# def initialize(user)
# Define abilities for the user here. For example:
#
#   return unless user.present?
#   can :read, :all
#   return unless user.admin?
#   can :manage, :all
#
# The first argument to `can` is the action you are giving the user
# permission to do.
# If you pass :manage it will apply to every action. Other common actions
# here are :read, :create, :update and :destroy.
#
# The second argument is the resource the user can perform the action on.
# If you pass :all it will apply to every resource. Otherwise pass a Ruby
# class of the resource.
#
# The third argument is an optional hash of conditions to further filter the
# objects.
# For example, here the user can only update published articles.
#
#   can :update, Article, published: true
#
# See the wiki for details:
# https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.axis_mundi?
      can :manage, :all
    elsif user.person_affiliation == 'employee'
      can :create, Container
      can :manage, Container, id: user.assignments.container_administrators.pluck(:container_id)
    elsif user.assignments.container_administrators.exists?
      can :manage, Container, id: user.assignments.container_administrators.pluck(:container_id)
    elsif user.profile.present?
      can :manage, Profile, user_id: user.id
      can :read, ApplicantDashboardController, user_id: user.id
    else
      can :create, Profile, user_id: user.id
    end

    # Allow managing Assignments only for Containers the user can manage
    can :create, Assignment do |assignment|
      can? :manage, assignment.container
    end
  end
end
