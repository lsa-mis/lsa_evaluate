# frozen_string_literal: true

class ContestInviteMailerPreview < ActionMailer::Preview
  def invite_to_submit
    invitation = ContestInvitation.includes(contest_instance: { contest_description: :container }).first ||
                 create_sample_invitation

    ContestInviteMailer.invite_to_submit(invitation)
  end

  private

  def create_sample_invitation
    contest_instance = ContestInstance.includes(contest_description: :container).first
    raise 'Create a contest instance before previewing ContestInviteMailer' if contest_instance.nil?

    ContestInvitation.create!(
      contest_instance: contest_instance,
      email: 'sample.invitee@umich.edu'
    )
  end
end
