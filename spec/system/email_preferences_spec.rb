require 'rails_helper'

RSpec.describe 'Email Preferences', type: :system do
  let(:department) { create(:department, name: 'Test Department') }
  let(:admin_user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, name: 'Test Container', department: department, contact_email: 'admin@example.com') }
  let(:contest_description) { create(:contest_description, :active, name: 'Test Contest', container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, date_open: 4.months.ago, date_closed: 3.months.ago) }

  # Create applicant user and entry
  let(:applicant) { create(:user, email: 'applicant@example.com') }
  let(:profile) { create(:profile, user: applicant) }
  let(:entry) { create(:entry, title: 'Test Entry', profile: profile, contest_instance: contest_instance) }

  # Create judge and rankings
  let(:judge) {
    judge = create(:user, :with_judge_role)
    create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
    judge
  }

  # Create judging rounds
  let(:judging_round) { create(:judging_round,
                              contest_instance: contest_instance,
                              round_number: 1,
                              start_date: 50.days.ago,
                              end_date: 30.days.ago,
                              completed: true) }

  before do
    # Create rankings
    create(:entry_ranking,
           entry: entry,
           judging_round: judging_round,
           user: judge,
           rank: 2,
           external_comments: 'Good submission!',
           selected_for_next_round: true)

    # Assign the judge to the round
    create(:round_judge_assignment, judging_round: judging_round, user: judge)

    # Sign in as admin
    login_as(admin_user, scope: :user)

    # Mock the mailer to avoid actually sending emails in tests
    allow(ResultsMailer).to receive(:entry_evaluation_notification).and_return(double(deliver_now: true, deliver_later: true))
  end

  it 'displays the email preferences form', :js do
    # Visit the email preferences page directly
    visit email_preferences_container_contest_description_contest_instance_path(
      container,
      contest_description,
      contest_instance,
      round_id: judging_round.id
    )

    # Verify we're on the email preferences page
    expect(page).to have_content('Email Results Preferences')
    expect(page).to have_content('Round 1 Email Content Options')

    # Check that both checkboxes exist
    expect(page).to have_field('include_average_ranking')
    expect(page).to have_field('include_advancement_status')
  end
end
