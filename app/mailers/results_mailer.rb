class ResultsMailer < ApplicationMailer
  def entry_evaluation_notification(entry, round)
    @entry = entry
    @round = round
    @profile = entry.profile
    @user = @profile.user
    @contest_instance = entry.contest_instance
    @contest_description = @contest_instance.contest_description
    @container = @contest_description.container

    # Get the contact email from the container, with fallbacks if not present
    @contact_email = @container.contact_email.presence ||
                    Rails.application.credentials.dig(:mailer, :default_contact_email) ||
                    Rails.application.credentials.dig(:devise, :mailer_sender) ||
                    'contests@example.com'

    # Get all rankings for this entry in this round
    @rankings = EntryRanking.where(entry: @entry, judging_round: @round)

    # Calculate the average rank
    @avg_rank = @round.average_rank_for_entry(@entry)

    # Check if the entry was selected for the next round
    @selected_for_next_round = @rankings.any?(&:selected_for_next_round?)

    # Only include external comments that are meant to be shared with applicants
    # and include the judge information with each comment
    @external_comments_with_judges = @rankings.map do |ranking|
      if ranking.external_comments.present? && !ranking.external_comments.empty?
        {
          comment: ranking.external_comments,
          judge: ranking.user.display_name_or_first_name_last_name
        }
      end
    end.compact

    subject = "Evaluation Results for \"#{@entry.title}\" - #{@contest_description.name}"

    # Set mail options - override reply_to if container has a contact email
    mail_options = {
      to: @user.email,
      subject: subject
    }

    # Override reply_to with container's contact_email if present
    mail_options[:reply_to] = @contact_email if @container.contact_email.present?

    mail(mail_options)
  end
end
