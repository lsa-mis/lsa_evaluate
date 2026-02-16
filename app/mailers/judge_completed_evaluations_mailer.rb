# frozen_string_literal: true

class JudgeCompletedEvaluationsMailer < ApplicationMailer
  def notify_contact(judge, judging_round)
    @judge = judge
    @judging_round = judging_round
    @contest_instance = judging_round.contest_instance
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container
    @judge_email = judge.normalize_email

    to_email = @container.contact_email.presence
    unless to_email
      raise ArgumentError, "contact_email is required for JudgeCompletedEvaluationsMailer.notify_contact"
    end

    subject = "Judge completed evaluations: #{@contest_description.name} - Round #{@judging_round.round_number}"

    mail(
      to: to_email,
      subject: subject,
      reply_to: @judge_email
    )
  end
end
