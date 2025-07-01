class JudgingInstructionsMailerPreview < ActionMailer::Preview
  def send_instructions
    # Find or create sample data for preview
    round_judge_assignment = RoundJudgeAssignment.joins(:user, :judging_round)
                                                 .joins(user: :roles)
                                                 .where(roles: { kind: 'Judge' })
                                                 .first

    if round_judge_assignment.nil?
      # Create sample data if none exists
      judge = User.joins(:roles).where(roles: { kind: 'Judge' }).first || create_sample_judge
      judging_round = JudgingRound.includes(:contest_instance).first || create_sample_judging_round

      round_judge_assignment = RoundJudgeAssignment.create!(
        user: judge,
        judging_round: judging_round
      )
    end

    # Ensure the judging round has special instructions for preview
    if round_judge_assignment.judging_round.special_instructions.blank?
      round_judge_assignment.judging_round.update!(
        special_instructions: sample_special_instructions
      )
    end

    JudgingInstructionsMailer.send_instructions(round_judge_assignment)
  end

  private

  def create_sample_judge
    judge = User.create!(
      email: "sample_judge@umich.edu",
      first_name: "Sample",
      last_name: "Judge",
      uid: "sample_judge",
      password: "password123",
      password_confirmation: "password123"
    )

    # Add judge role
    judge_role = Role.find_or_create_by!(kind: 'Judge', description: 'Judge')
    judge.roles << judge_role

    judge
  end

  def create_sample_judging_round
    contest_instance = ContestInstance.first || create_sample_contest_instance

    JudgingRound.create!(
      contest_instance: contest_instance,
      round_number: 1,
      start_date: 1.day.from_now,
      end_date: 7.days.from_now,
      required_entries_count: 5,
      require_internal_comments: true,
      min_internal_comment_words: 50,
      require_external_comments: true,
      min_external_comment_words: 100,
      special_instructions: sample_special_instructions
    )
  end

  def create_sample_contest_instance
    contest_description = ContestDescription.first || create_sample_contest_description

    ContestInstance.create!(
      contest_description: contest_description,
      date_open: 1.month.ago,
      date_closed: 1.day.ago,
      created_by: "admin@umich.edu",
      active: true
    )
  end

  def create_sample_contest_description
    container = Container.first || create_sample_container

    ContestDescription.create!(
      name: "Sample Writing Contest",
      container: container,
      active: true
    )
  end

  def create_sample_container
    Container.create!(
      name: "Sample Container",
      contact_email: "contests@umich.edu"
    )
  end

  def sample_special_instructions
    <<~INSTRUCTIONS
      Thank you for agreeing to judge this contest. Here are some important guidelines:

      1. **Evaluation Criteria:**
         - Originality and creativity (25%)
         - Quality of writing and style (25%)
         - Adherence to contest theme (25%)
         - Overall impact and engagement (25%)

      2. **Ranking Guidelines:**
         - Please rank entries from 1 (best) to N (number of entries you review)
         - Avoid giving the same rank to multiple entries
         - Consider the target audience when evaluating

      3. **Comment Requirements:**
         - Internal comments are for contest administrators only
         - External comments will be shared with contestants
         - Please be constructive and encouraging in external comments

      4. **Conflict of Interest:**
         - If you recognize an entry or have any conflict of interest, please notify the contest administrator immediately

      5. **Confidentiality:**
         - Please do not discuss entries with other judges during the evaluation period
         - All entries should be treated as confidential

      If you have any questions, please don't hesitate to reach out to the contest administrator.
    INSTRUCTIONS
  end
end
