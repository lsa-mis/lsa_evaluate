class ResultsMailerPreview < ActionMailer::Preview
  def entry_evaluation_notification
    # Create sample data for preview
    entry = Entry.first || create_sample_entry
    round = JudgingRound.first || create_sample_round

    ResultsMailer.entry_evaluation_notification(entry, round)
  end

  private

  def create_sample_entry
    Entry.create!(
      title: "Sample Entry",
      profile: Profile.first || create_sample_profile,
      contest_instance: ContestInstance.first || create_sample_contest_instance
    )
  end

  def create_sample_profile
    Profile.create!(
      user: User.first || create_sample_user
    )
  end

  def create_sample_user
    User.create!(
      email: "sample@example.com",
      password: "password123",
      first_name: "Sample",
      last_name: "User"
    )
  end

  def create_sample_contest_instance
    ContestInstance.create!(
      contest_description: ContestDescription.first || create_sample_contest_description
    )
  end

  def create_sample_contest_description
    ContestDescription.create!(
      name: "Sample Contest",
      container: Container.first || create_sample_container
    )
  end

  def create_sample_container
    Container.create!(
      name: "Sample Container",
      contact_email: "contests@example.com"
    )
  end

  def create_sample_round
    JudgingRound.create!(
      name: "Sample Round"
    )
  end
end
