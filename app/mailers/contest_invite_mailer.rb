# frozen_string_literal: true

class ContestInviteMailer < ApplicationMailer
  def invite_to_submit(contest_invitation)
    @invitation = contest_invitation
    @contest_instance = contest_invitation.contest_instance
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container
    @invite_url = contest_invite_url(token: @contest_instance.access_token)
    @contact_email = @container.contact_email.presence || 'lsa-evaluate-support@umich.edu'
    @date_open = @contest_instance.date_open
    @date_closed = @contest_instance.date_closed

    mail_options = {
      to: @invitation.email,
      subject: "You're invited to submit: #{@contest_description.name}"
    }
    mail_options[:reply_to] = @container.contact_email if @container.contact_email.present?

    mail(mail_options)
  end
end
