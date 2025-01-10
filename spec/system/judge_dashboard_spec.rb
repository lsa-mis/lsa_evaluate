require 'rails_helper'

RSpec.describe 'Judge Dashboard', type: :system do
  include JudgingAssignmentsHelper  # Include the correct helper module

  def first_entry_title
    all('[data-entry-id]').first.text.split('(').first.strip
  end

  def last_entry_title
    all('[data-entry-id]').last.text.split('(').first.strip
  end

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
      min_internal_comment_words: 10,
      required_entries_count: 7
    )
  }
  let!(:entry) { create(:entry, contest_instance: contest_instance, deleted: false, title: 'Sample Entry Title') }
  let!(:additional_entries) {
    (2..8).map do |n|
      create(:entry, contest_instance: contest_instance, deleted: false, title: "Sample Entry Title #{n}")
    end
  }
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
        expect(page).to have_content('Available Entries')
        expect(page).to have_content('entryID:')
        expect(page).to have_content(entry.id)
        expect(page).to have_content('Sample Entry Title')
        expect(page).to have_link('View Entry')
      end
    end

    it 'allows evaluating an entry' do
      # Expand the accordion
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        # Find the specific entry's card and click its View Entry link
        within("[data-entry-id='#{entry.id}']") do
          click_link 'View Entry'
        end
      end

      # Check evaluation page content
      expect(page).to have_content("#{entry.title}")
      expect(page).to have_content("entryID: #{entry.id}")
      expect(page).to have_content('Test Contest')
      expect(page).to have_content("Round: #{judging_round.round_number}")

      # Drag evaluation to Selected Entries


      # Entry to have been moved to Selected Entries and the record updated


      # Should redirect back to dashboard


      # Expand accordion again to check updated status
      find('.accordion-button').click
      sleep 0.5
    end

    it 'allows evaluating an entry via drag and drop' do
      # Expand the accordion
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        # Find the draggable entry element
        entry_element = find("[data-entry-id='#{entry.id}']")

        # Find the drop target in Selected Entries section
        drop_target = find('.rating-space[data-controller="entry-drag"]')

        # Perform drag and drop operation
        entry_element.drag_to(drop_target)

        # Fill in comments in the entry card form
        within("[data-entry-id='#{entry.id}']") do
          fill_in 'Internal Comments', with: 'These are detailed internal comments about the entry that meet the minimum word requirement.'
          fill_in 'External Comments', with: 'Constructive feedback for the applicant about their submission.'
        end

        # Wait for the update to complete
        expect(page).to have_content('Evaluation submitted successfully')

        # Verify entry moved to Selected Entries
        within('.rating-space') do
          expect(page).to have_content(entry.title)
        end

        # Verify entry removed from Available Entries
        within('.entries-list') do
          expect(page).to have_no_content(entry.title)
        end
      end
    end

    it 'validates required comments during drag and drop evaluation' do
      # Expand the accordion
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        # Find and drag the entry
        entry_element = find("[data-entry-id='#{entry.id}']")
        drop_target = find('.rating-space[data-controller="entry-drag"]')
        entry_element.drag_to(drop_target)

        # Try to submit with insufficient comments
        within("[data-entry-id='#{entry.id}']") do
          fill_in 'Internal Comments', with: 'Too short'
          fill_in 'External Comments', with: 'OK'
        end

        # Verify error messages appear in the form
        expect(page).to have_content('Internal comments must be at least 10 words')

        # Entry should remain in Available Entries
        within('.entries-list') do
          expect(page).to have_content(entry.title)
        end
      end
    end

    it 'allows reordering entries within Selected Entries section' do
      # Create rankings for multiple entries
      rankings = [ entry, *additional_entries.take(6) ].each_with_index do |e, index|
        create(:entry_ranking, entry: e, user: judge, judging_round: judging_round, rank: index + 1)
      end

      visit judge_dashboard_path
      find('.accordion-button').click
      sleep 0.5

      within('.rating-space') do
        # Verify initial state shows correct number of entries
        expect(page).to have_css('[data-entry-id]', count: 7)

        # Find the first and last entries
        first_entry = find("[data-entry-id='#{entry.id}']")
        last_entry = find("[data-entry-id='#{additional_entries[5].id}']")

        # Drag last entry to top
        last_entry.drag_to(first_entry)

        # Verify the order has changed
        expect(page).to have_css('[data-entry-id]', count: 7)
        expect(first_entry_title).to eq(additional_entries[5].title)
        expect(last_entry_title).to eq(additional_entries[4].title)

        # Verify the rankings were updated in the database
        expect(EntryRanking.find_by(entry: additional_entries[5]).rank).to eq(1)
        expect(EntryRanking.find_by(entry: entry).rank).to eq(2)
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


        # Verify the updates are shown on the dashboard
      end
    end

    context 'when viewing eligibility rules' do
      it 'displays eligibility rules button in the accordion' do
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          expect(page).to have_button('View Eligibility Rules')
        end
      end

      it 'opens eligibility modal when clicking the button' do
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          click_button 'View Eligibility Rules'

          # Check modal appears and has content
          within('.modal.show') do
            expect(page).to have_content('Eligibility Rules')
            expect(page).to have_css('.modal-body')
            expect(page).to have_button('Close')
          end
        end
      end

      it 'loads eligibility rules content via AJAX' do
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          click_button 'View Eligibility Rules'

          # Wait for modal to be visible
          expect(page).to have_css('.modal.show')

          # Wait for content to load - just check for the text
          expect(page).to have_content('Eligibility rules for Test Contest')
        end
      end
    end
  end
end
