require 'rails_helper'

RSpec.describe 'Judge Dashboard', type: :system do
  include JudgingAssignmentsHelper  # Include the correct helper module

  let(:judge) { create(:user, first_name: 'John', last_name: 'Doe', email: 'judge+gmail.com@umich.edu') }
  let(:judge_role) { create(:role, :judge) }
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container, name: 'Test Contest') }
  let(:contest_instance) { create(:contest_instance,
    contest_description: contest_description,
    date_open: 2.months.ago,
    date_closed: 1.month.ago,
    active: true,
    created_by: judge.email
  ) }
  let!(:judging_round) {
    create(:judging_round,
      contest_instance: contest_instance,
      start_date: 2.weeks.ago,
      end_date: 1.week.from_now,
      active: true,
      round_number: 1,
      require_internal_comments: true,
      min_internal_comment_words: 10
    )
  }
  let!(:entry) { create(:entry, contest_instance: contest_instance, deleted: false, title: 'Sample Entry Title') }
  let!(:entry_ranking) { nil }

  context 'when user is not authenticated' do
    it 'redirects to login page' do
      visit judge_dashboard_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'when user is authenticated but not a judge' do
    let(:non_judge) { create(:user) }

    before do
      sign_in non_judge
    end

    it 'redirects to root with access denied message' do
      visit judge_dashboard_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content('Access denied')
    end
  end

  context 'when user is an authenticated judge' do
    before do
      create(:user_role, user: judge, role: judge_role)
      create(:assignment, user: judge, container: container, role: judge_role)
      create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
      sign_in judge
      visit judge_dashboard_path
    end

    it 'displays the judge information correctly' do
      expect(page).to have_content('Judge Dashboard')
      expect(page).to have_content("Hello #{judge.first_name} #{judge.last_name} (#{display_email(judge.email)})")
      expect(page).to have_content('Test Contest')

      # Expand the accordion
      find('.accordion-button').click

      # Wait for animation to complete
      sleep 0.5

      # Now check the content inside the expanded accordion
      within('.accordion-collapse.show') do
        expect(page).to have_content('Entries to Judge')
        expect(page).to have_content('Entry ID')
        expect(page).to have_content(entry.id)
        expect(page).to have_content('Sample Entry Title')
        expect(page).to have_content('Not ranked')
        expect(page).to have_content('Pending')
        expect(page).to have_link('View Entry')
        expect(page).to have_link('Evaluate')
      end
    end

    it 'allows evaluating an entry' do
      # Expand the accordion
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        click_link 'Evaluate'
      end

      # Check evaluation page content
      expect(page).to have_content("Entry: #{entry.title}")
      expect(page).to have_content('Test Contest')
      expect(page).to have_content("Round: #{judging_round.round_number}")

      # Fill in evaluation
      fill_in 'entry_ranking[rank]', with: '1'
      fill_in 'entry_ranking[internal_comments]', with: 'This is a detailed evaluation of the entry with more than ten words to meet the minimum requirement.'

      # Submit the form
      click_button 'Save Evaluation'

      # Should redirect back to dashboard
      expect(page).to have_current_path(judge_dashboard_path)
      expect(page).to have_content('Evaluation saved successfully')

      # Expand accordion again to check updated status
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        expect(page).to have_content('1') # The ranking we entered
        expect(page).to have_content('Evaluated')
      end
    end

    it 'only shows assigned contests' do
      # Create another contest that the judge is not assigned to
      other_container = create(:container)
      other_contest_description = create(:contest_description, container: other_container, name: 'Other Contest')
      unassigned_contest = create(:contest_instance,
        contest_description: other_contest_description,
        date_open: 2.months.ago,
        date_closed: 1.month.ago,
        active: true,
        created_by: judge.email
      )
      create(:judging_round,
        contest_instance: unassigned_contest,
        start_date: 2.weeks.ago,
        end_date: 1.week.from_now,
        active: true,
        round_number: 1
      )
      create(:entry, contest_instance: unassigned_contest, deleted: false, title: 'Other Entry')

      visit judge_dashboard_path

      expect(page).to have_content('Test Contest')
      expect(page).to have_no_content('Other Contest')

      # Expand the accordion
      find('.accordion-button').click

      # Wait for animation to complete
      sleep 0.5

      # Check the entries
      within('.accordion-collapse.show') do
        expect(page).to have_content('Sample Entry Title')
        expect(page).to have_no_content('Other Entry')
      end
    end

    it 'shows empty state when no contests are assigned' do
      JudgingAssignment.destroy_all # Remove all assignments
      visit judge_dashboard_path
      expect(page).to have_content('You have not been assigned to judge any contests')
    end

    context 'when attempting to access unassigned contest data' do
      let(:unassigned_container) { create(:container) }
      let(:unassigned_contest_description) { create(:contest_description, container: unassigned_container, name: 'Unassigned Contest') }
      let(:unassigned_contest) { create(:contest_instance,
        contest_description: unassigned_contest_description,
        date_open: 2.months.ago,
        date_closed: 1.month.ago,
        active: true,
        created_by: judge.email
      ) }

      it 'prevents access to unassigned contest entries' do
        visit container_contest_description_contest_instance_path(
          unassigned_container,
          unassigned_contest_description,
          unassigned_contest
        )

        expect(page).to have_current_path(root_path)
        expect(page).to have_content('!!! Not authorized !!!')
      end
    end

    context 'when updating an existing evaluation' do
      it 'allows updating an existing evaluation' do
        # Create the entry_ranking after all assignments are set up
        entry_ranking = create(:entry_ranking,
          entry: entry,
          judging_round: judging_round,
          user: judge,
          rank: 2,
          internal_comments: 'Initial evaluation comments that need to be updated with new information.'
        )

        visit judge_dashboard_path
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          expect(page).to have_content('2') # Initial ranking
          expect(page).to have_content('Evaluated')
          click_link 'Evaluate'
        end

        expect(page).to have_field('entry_ranking[rank]', with: '2')
        expect(page).to have_field('entry_ranking[internal_comments]', with: entry_ranking.internal_comments)

        fill_in 'entry_ranking[rank]', with: '3'
        fill_in 'entry_ranking[internal_comments]', with: 'Updated evaluation with new insights and detailed comments about the entry.'

        click_button 'Save Evaluation'

        expect(page).to have_current_path(judge_dashboard_path)
        expect(page).to have_content('Evaluation updated successfully')

        # Verify the updates are shown on the dashboard
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          expect(page).to have_content('3') # Updated ranking
        end
      end
    end
  end
end
