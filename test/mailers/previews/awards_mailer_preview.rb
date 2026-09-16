class AwardsMailerPreview < ActionMailer::Preview
  def award_notice
    entry = Entry.awarded.includes(:entry_awards, profile: :user, contest_instance: { contest_description: :container }).first
    AwardsMailer.award_notice(entry, include_amounts: true) if entry
  end
end
