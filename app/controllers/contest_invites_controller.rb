# frozen_string_literal: true

class ContestInvitesController < ApplicationController
  def show
    @contest_instance = ContestInstance.find_by!(access_token: params[:token])

    if @contest_instance.private_visibility? && @contest_instance.invite_list? && !@contest_instance.invited?(current_user)
      redirect_to applicant_dashboard_path, alert: 'You are not invited to submit to this contest.'
      return
    end

    unless current_user.profile
      remember_pending_contest_invite!(@contest_instance)
      redirect_to new_profile_path, alert: 'Please create your profile before accessing this contest.'
      return
    end

    redeem_contest_instance!(@contest_instance)

    unless @contest_instance.open?
      redirect_to applicant_dashboard_path, alert: 'This contest is not currently open for submissions.'
      return
    end

    unless @contest_instance.available_for_profile?(current_user.profile)
      redirect_to applicant_dashboard_path,
                  alert: 'You are not eligible to submit to this contest (class level or entry limit).'
      return
    end

    redirect_to new_entry_path(contest_instance_id: @contest_instance.id),
                notice: "Welcome to #{@contest_instance.contest_description.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to applicant_dashboard_path, alert: 'Invalid or expired contest invite link.'
  end
end
