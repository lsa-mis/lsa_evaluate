class JudgingInstructionsMailer < ApplicationMailer
  def send_instructions(round_judge_assignment, cc_emails: [])
    @round_judge_assignment = round_judge_assignment
    @judge = @round_judge_assignment.user
    @judging_round = @round_judge_assignment.judging_round
    @contest_instance = @judging_round.contest_instance
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container
    @judge_email = @judge.normalize_email

    # Get the special instructions from the judging round
    @special_instructions = @judging_round.special_instructions.presence

    # Get the contact email for display in the email body
    # Use container's contact_email if present, otherwise use the default reply-to email
    @contact_email = @container.contact_email.presence || 'LSA Evaluate Support <lsa-evaluate-support@umich.edu>'

    subject = "Judging Instructions for #{@contest_description.name} - Round #{@judging_round.round_number}"

    # Set mail options
    mail_options = {
      to: @judge_email,
      subject: subject
    }

    # Add CC to collection administrators if provided
    mail_options[:cc] = cc_emails if cc_emails.any?

    # Override reply_to with container's contact_email if present
    # If not present, the default reply-to from ApplicationMailer will be used
    mail_options[:reply_to] = @container.contact_email if @container.contact_email.present?

    mail(mail_options)
  end
end
