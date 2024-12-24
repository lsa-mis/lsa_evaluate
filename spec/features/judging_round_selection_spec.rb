require 'rails_helper'

RSpec.describe 'Judging Round Selection', type: :system do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }
  let(:admin_role) { create(:role, :admin) }
  let(:collection_admin) { create(:user, :with_collection_admin_role) }
  let(:judge1) { create(:user, :with_judge_role) }
  let(:judge2) { create(:user, :with_judge_role) }
  let(:entry1) { create(:entry, contest_instance: contest_instance, title: 'First Entry') }
  let(:entry2) { create(:entry, contest_instance: contest_instance, title: 'Second Entry') }

  before do
    # Assign container role to collection admin using the explicit admin role
    create(:assignment, user: collection_admin, container: container, role: admin_role)

    # Create judging assignments
    create(:judging_assignment, user: judge1, contest_instance: contest_instance)
    create(:judging_assignment, user: judge2, contest_instance: contest_instance)
    create(:round_judge_assignment, user: judge1, judging_round: judging_round)
    create(:round_judge_assignment, user: judge2, judging_round: judging_round)

    # Create rankings with detailed comments
    create(:entry_ranking, :with_detailed_comments,
      user: judge1, entry: entry1, judging_round: judging_round, rank: 1
    )
    create(:entry_ranking, :with_detailed_comments,
      user: judge1, entry: entry2, judging_round: judging_round, rank: 2
    )
    create(:entry_ranking, :with_detailed_comments,
      user: judge2, entry: entry1, judging_round: judging_round, rank: 2
    )
    create(:entry_ranking, :with_detailed_comments,
      user: judge2, entry: entry2, judging_round: judging_round, rank: 1
    )
  end

  context 'when logged in as collection admin' do
    before do
      sign_in collection_admin
      visit container_contest_description_contest_instance_judging_assignments_path(
        container, contest_description, contest_instance
      )
      click_link 'Review Rankings & Select Entries'
    end

    it 'displays all entries with their rankings' do
      expect(page).to have_content('First Entry')
      expect(page).to have_content('Second Entry')
      expect(page).to have_content('1.5') # Average rank for entry1 (1 + 2 / 2)
      expect(page).to have_content('1.5') # Average rank for entry2 (2 + 1 / 2)
    end

    it 'allows selecting entries for the next round', :js do
      within('tr', text: 'First Entry') do
        find('input[type="checkbox"]').click
      end

      # Wait for Turbo Stream update and flash message
      expect(page).to have_css('.alert.alert-success', text: 'Entry selection updated successfully', wait: 5)

      # Verify the entry was selected
      entry1_ranking = EntryRanking.find_by(entry: entry1, judging_round: judging_round)
      expect(entry1_ranking.selected_for_next_round).to be true
    end

    it 'allows deselecting entries', :js do
      # First select an entry
      within('tr', text: 'Second Entry') do
        find('input[type="checkbox"]').click
      end

      # Wait for Turbo Stream update and flash message
      expect(page).to have_css('.alert.alert-success', text: 'Entry selection updated successfully', wait: 5)

      # Then deselect it
      within('tr', text: 'Second Entry') do
        find('input[type="checkbox"]').click
      end

      # Wait for Turbo Stream update and flash message
      expect(page).to have_css('.alert.alert-success', text: 'Entry selection updated successfully', wait: 5)

      # Verify the entry was deselected
      entry2_ranking = EntryRanking.find_by(entry: entry2, judging_round: judging_round)
      expect(entry2_ranking.selected_for_next_round).to be false
    end

    it 'shows judge comments when clicking view comments', :js do
      within('tr', text: 'First Entry') do
        first('button', text: 'View Comments').click
      end

      # Wait for Bootstrap collapse animation
      expect(page).to have_css('.collapse.show', wait: 5)
      expect(page).to have_content('Internal Comments')
      expect(page).to have_content('External Comments')
    end
  end

  context 'when logged in as a judge' do
    before do
      sign_in judge1
      visit container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, judging_round
      )
    end

    it 'denies access to the selection interface' do
      expect(page).to have_content('Access denied')
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end
end
