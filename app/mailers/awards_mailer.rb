# frozen_string_literal: true

class AwardsMailer < ApplicationMailer
  def award_notice(entry, include_amounts: false)
    @entry = entry
    @profile = entry.profile
    @user = @profile.user
    @contest_instance = entry.contest_instance
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container
    @include_amounts = include_amounts
    @primary_award = entry.primary_entry_award
    @add_on_awards = entry.add_on_entry_awards
    @contact_email = @container.contact_email.presence || 'LSA Evaluate Support <lsa-evaluate-support@umich.edu>'

    mail_options = {
      to: @user.email,
      subject: "Award notice for \"#{@entry.title}\" - #{@contest_description.name}"
    }
    mail_options[:reply_to] = @contact_email if @container.contact_email.present?

    mail(mail_options)
  end
end
