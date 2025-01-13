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
      expect(page).to have_content('!!! Not authorized !!!')
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

    xit 'allows selecting an entry for evaluation', :js do
      visit judge_dashboard_path
      find('.accordion-button').click
      sleep 1 # Wait for accordion animation

      within('.accordion-collapse.show') do
        # Find and click the first available entry
        entries_list = find('.entries-list[data-entry-drag-target="availableEntries"]')
        first_entry = entries_list.all('.card[data-entry-id]').first
        entry_id = first_entry['data-entry-id']
        entry_title = first_entry.find('h6').text

        puts "\nBefore click:"
        puts "Entry ID: #{entry_id}"
        puts "Entry title: #{entry_title}"
        puts "Available entries count: #{entries_list.all('.card[data-entry-id]').count}"

        # Try clicking the View Entry link instead of the card
        within(first_entry) do
          click_link 'View Entry'
        end

        # Wait for Turbo/AJAX
        sleep 2
        puts "\nAfter click:"
        puts "Available entries count: #{entries_list.all('.card[data-entry-id]').count}"
        puts "Rated entries HTML:"
        puts page.find('.rated-entries[data-entry-drag-target="ratedEntries"]', wait: 5).text rescue "Not found"

        # Verify the entry appears in rated entries with longer wait time and more specific selector
        within('.rated-entries[data-entry-drag-target="ratedEntries"]') do
          expect(page).to have_css(".card[data-entry-id='#{entry_id}']", wait: 10)
          expect(page).to have_content(entry_title)
          expect(page).to have_css('.badge', text: /Rank:\s*1/i)
        end

        # Verify entry is removed from available entries
        within('.entries-list[data-entry-drag-target="availableEntries"]') do
          expect(page).to have_no_css("[data-entry-id='#{entry_id}']")
        end

        # Verify counter updated
        expect(page).to have_css('[data-entry-drag-target="counter"]', text: '1/7')
      end
    end

    xit 'allows reordering entries using rank buttons', :js do
      # Create rankings for multiple entries
      rankings = [ entry, *additional_entries.take(6) ].each_with_index do |e, index|
        create(:entry_ranking, entry: e, user: judge, judging_round: judging_round, rank: index + 1)
      end

      visit judge_dashboard_path
      find('.accordion-button').click
      sleep 0.5

      within('.row[data-controller="entry-drag"]') do
        within('.rated-entries') do
          expect(page).to have_css('[data-entry-id]', count: 7)

          # Find entries by their IDs
          first_entry = find("[data-entry-id='#{entry.id}']")
          last_entry = find("[data-entry-id='#{additional_entries[5].id}']")

          # Click rank adjustment buttons
          within(last_entry) do
            click_button 'Move to Top'
          end
          sleep 1

          # Verify the order has changed
          first_entry_after = find('.rated-entries [data-entry-id]', match: :first)
          expect(first_entry_after['data-entry-id']).to eq(additional_entries[5].id.to_s)

          # Verify database updates
          expect(EntryRanking.find_by(entry: additional_entries[5]).rank).to eq(1)
          expect(EntryRanking.find_by(entry: entry).rank).to eq(2)
        end
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
        end

        # Wait for Bootstrap modal to be fully shown
        expect(page).to have_css('#eligibilityModal[style*="display: block"]', wait: 5)

        # Now check the content
        within('#eligibilityModal') do
          expect(page).to have_content('Eligibility Rules')
          expect(page).to have_css('.modal-body')
          expect(page).to have_button('Close')
        end
      end

      it 'loads eligibility rules content via AJAX' do
        find('.accordion-button').click
        sleep 0.5

        within('.accordion-collapse.show') do
          click_button 'View Eligibility Rules'
        end

        # Wait for Bootstrap modal to be fully shown and content loaded
        expect(page).to have_css('#eligibilityModal[style*="display: block"]', wait: 5)
        expect(page).to have_content('Eligibility rules for Test Contest', wait: 5)
      end
    end

    xit 'creates an entry ranking when selecting an entry', :js do
      visit judge_dashboard_path
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        # Debug initial state
        puts "\nInitial state:"
        puts "Available entries content:"
        puts find('.entries-list[data-entry-drag-target="availableEntries"]').text

        # Find the first available entry more specifically
        first_entry = all('.entries-list[data-entry-drag-target="availableEntries"] .card[data-entry-id]').first
        entry_id = first_entry['data-entry-id']
        entry_title = first_entry.find('h6').text

        puts "\nSelected entry:"
        puts "ID: #{entry_id}"
        puts "Title: #{entry_title}"
        puts "Full content: #{first_entry.text}"

        # Click the entry to select it
        first_entry.click

        # Wait for AJAX
        sleep 1

        # Debug after click
        puts "\nAfter click:"
        puts "Rated entries content:"
        puts find('.rated-entries[data-entry-drag-target="ratedEntries"]').text

        # Verify the entry appears in rated entries with longer wait time
        within('.rated-entries[data-entry-drag-target="ratedEntries"]') do
          expect(page).to have_css("[data-entry-id='#{entry_id}']", wait: 10)
          expect(page).to have_content(entry_title)
          expect(page).to have_css('.badge', text: 'Rank: 1')
        end

        # Verify counter updated
        expect(page).to have_css('[data-entry-drag-target="counter"]', text: '1/7')

        # Verify database record
        ranking = EntryRanking.find_by(entry_id: entry_id, user: judge, judging_round: judging_round)
        expect(ranking).to be_present
        expect(ranking.rank).to eq(1)
      end
    end

    it 'updates UI when entry ranking is created', :js do
      # Create ranking through the backend
      ranking = create(:entry_ranking,
        entry: entry,
        user: judge,
        judging_round: judging_round,
        rank: 1
      )

      visit judge_dashboard_path
      find('.accordion-button').click
      sleep 0.5

      within('.accordion-collapse.show') do
        # Verify entry appears in rated entries
        within('.rated-entries[data-entry-drag-target="ratedEntries"]') do
          expect(page).to have_css("[data-entry-id='#{entry.id}']")
          expect(page).to have_content(entry.title)
          expect(page).to have_css('.badge', text: 'Rank: 1')
        end

        # Verify entry is not in available entries
        within('.entries-list[data-entry-drag-target="availableEntries"]') do
          expect(page).to have_no_css("[data-entry-id='#{entry.id}']")
        end

        # Verify counter
        expect(page).to have_css('[data-entry-drag-target="counter"]', text: '1/7')
      end
    end
  end
end
