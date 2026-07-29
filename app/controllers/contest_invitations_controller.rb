# frozen_string_literal: true

class ContestInvitationsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description
  before_action :set_contest_instance
  before_action :authorize_contest_instance

  def create
    emails = parse_emails(params[:emails].presence || params.dig(:contest_invitation, :email))
    created_invitations = []
    skipped = []

    emails.each do |email|
      invitation = @contest_instance.contest_invitations.find_or_initialize_by(email: email)
      if invitation.new_record?
        invitation.invited_by = current_user
        if invitation.save
          created_invitations << invitation
        else
          skipped << email
        end
      else
        skipped << email
      end
    end

    created_invitations.each do |invitation|
      ContestInviteMailer.invite_to_submit(invitation).deliver_later
    end

    notice_parts = []
    if created_invitations.any?
      notice_parts << "Added #{created_invitations.size} invite#{'s' unless created_invitations.size == 1}."
      notice_parts << "Invite email#{'s' unless created_invitations.size == 1} queued for #{created_invitations.size} new invitee#{'s' unless created_invitations.size == 1}."
    end
    notice_parts << "Skipped #{skipped.size} duplicate or invalid email#{'s' unless skipped.size == 1}." if skipped.any?

    redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                notice: notice_parts.presence&.join(' ') || 'No invitations were added.'
  end

  def destroy
    invitation = @contest_instance.contest_invitations.find(params[:id])
    invitation.destroy
    redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                notice: 'Invitee removed.'
  end

  def email_all
    authorize @contest_instance, :send_invite_emails?

    invitations = @contest_instance.contest_invitations
    if invitations.none?
      redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                  alert: 'There are no invitees to email.'
      return
    end

    invitations.find_each do |invitation|
      ContestInviteMailer.invite_to_submit(invitation).deliver_later
    end

    redirect_to container_contest_description_contest_instance_path(@container, @contest_description, @contest_instance),
                notice: "Queued invite emails for #{invitations.count} invitee#{'s' unless invitations.count == 1}."
  end

  private

  def set_container
    @container = policy_scope(Container).find(params[:container_id])
  end

  def set_contest_description
    @contest_description = @container.contest_descriptions.find(params[:contest_description_id])
  end

  def set_contest_instance
    @contest_instance = @contest_description.contest_instances.find(params[:contest_instance_id])
  end

  def authorize_contest_instance
    authorize @contest_instance, :manage_invitations?
  end

  def parse_emails(raw)
    Array(raw.to_s.split(/[\s,;]+/)).map { |email| email.strip.downcase }.reject(&:blank?).uniq
  end
end
