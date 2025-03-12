require 'rails_helper'

RSpec.describe 'Judging Results Email', type: :system do
  let(:department) { create(:department, name: 'Test Department') }
  let(:admin_user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, name: 'Test Container', department: department, contact_email: 'admin@example.com') }
  let(:contest_description) { create(:contest_description, name: 'Test Contest', container: container) }
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

  let(:incomplete_round) { create(:judging_round,
                                 contest_instance: contest_instance,
                                 round_number: 2,
                                 start_date: 20.days.ago,
                                 end_date: 10.days.ago,
                                 completed: false) }

  before do
    # Create rankings
    create(:entry_ranking,
           entry: entry,
           judging_round: judging_round,
           user: judge,
           rank: 2,
           external_comments: 'Good submission!',
           selected_for_next_round: true)

    create(:entry_ranking,
           entry: entry,
           judging_round: incomplete_round,
           user: judge)

    # Assign the judge to the rounds
    create(:round_judge_assignment, judging_round: judging_round, user: judge)
    create(:round_judge_assignment, judging_round: incomplete_round, user: judge)

    # Set up email counter
    judging_round.update(emails_sent_count: 1)

    # Sign in as admin
    login_as(admin_user, scope: :user)

    # Mock the mailer to avoid actually sending emails in tests
    allow(ResultsMailer).to receive(:entry_evaluation_notification).and_return(double(deliver_now: true, deliver_later: true))
  end

  it 'shows completed round email counter and enables/disables buttons correctly', :js do
    # Visit the contest instance page
    visit container_contest_description_contest_instance_path(container, contest_description, contest_instance)

    # Click the Judging Results tab
    execute_script("document.getElementById('judging-results-tab').click()")
    sleep 1

    # Verify we can see both rounds
    expect(page).to have_content('Round 1')
    expect(page).to have_content('Round 2')

    # Get all buttons with email text
    buttons = page.all('button', text: /Email round \d+ results/)

    # Check there are 2 buttons (one for each round)
    expect(buttons.size).to eq(2)

    # First button should be for round 1 and enabled
    expect(buttons[0].text).to include('Email round 1 results')
    expect(buttons[0]['disabled']).to eq('false').or eq(false).or be_nil

    # Second button should be for round 2 and disabled
    expect(buttons[1].text).to include('Email round 2 results')
    expect(buttons[1]['disabled']).to eq('true').or eq(true)

    # Check that the badge is displayed for round 1
    expect(page).to have_content('Emails sent: 1 time')
  end

  it 'sends emails and increments counter when button is clicked', :js do
    # Visit the contest instance page
    visit container_contest_description_contest_instance_path(container, contest_description, contest_instance)

    # Click the Judging Results tab
    execute_script("document.getElementById('judging-results-tab').click()")
    sleep 1

    # Initial badge count
    expect(page).to have_content('Emails sent: 1 time')

    # Click the email button for round 1
    accept_confirm do
      click_button 'Email round 1 results'
    end

    # Verify success message appears
    expect(page).to have_content('Successfully queued 1 evaluation result emails')

    # Refresh the page to ensure we're seeing the latest data
    visit current_path
    execute_script("document.getElementById('judging-results-tab').click()")
    sleep 1

    # Verify counter increased
    expect(page).to have_content('Emails sent: 2 times')
  end
end
