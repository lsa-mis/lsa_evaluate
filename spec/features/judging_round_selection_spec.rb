require 'rails_helper'

RSpec.describe 'Judging Round Selection', type: :system do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 1,
      completed: true,
      active: false,
      start_date: contest_instance.date_closed + 1.day,
      end_date: contest_instance.date_closed + 8.days
    ).tap { |jr| jr.update_column(:active, false) }
  end
  let(:next_judging_round) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 2,
      active: true,
      completed: false,
      start_date: judging_round.end_date + 1.day,
      end_date: judging_round.end_date + 8.days
    )
  end
  let(:admin_role) { create(:role, :admin) }
  let(:collection_admin) { create(:user, :with_collection_admin_role) }
  let(:judge1) { create(:user, :with_judge_role) }
  let(:judge2) { create(:user, :with_judge_role) }
  let(:entry1) { create(:entry, contest_instance: contest_instance, title: 'First Entry') }
  let(:entry2) { create(:entry, contest_instance: contest_instance, title: 'Second Entry') }

  def rankings_path
    container_contest_description_contest_instance_judging_round_path(
      container, contest_description, contest_instance, judging_round
    )
  end

  def next_round_checkbox(entry)
    find("#selected_for_next_round_checkbox_#{entry.id}")
  end

  before do
    # Create both judging rounds in sequence
    judging_round
    next_judging_round

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
      visit rankings_path
    end

    it 'displays all entries with their rankings' do
      expect(page).to have_content('First Entry')
      expect(page).to have_content('Second Entry')
      expect(page).to have_css('.badge.bg-secondary', text: '1', minimum: 2)
      expect(page).to have_css('.badge.bg-secondary', text: '2', minimum: 2)
    end

    it 'allows selecting entries for the next round', :js do
      within('tr', text: 'First Entry') do
        expect(next_round_checkbox(entry1)).not_to be_checked
        next_round_checkbox(entry1).click
      end

      within('tr', text: 'First Entry') do
        expect(page).to have_css("#selected_for_next_round_checkbox_#{entry1.id}:checked", wait: 10)
      end
      expect(page).to have_css('.alert.alert-success', text: 'Entry selection updated successfully', wait: 5)

      expect(EntryRanking.where(entry: entry1, judging_round: judging_round, selected_for_next_round: true).count).to eq(2)
    end

    it 'allows deselecting entries', :js do
      EntryRanking.where(entry: entry2, judging_round: judging_round)
                  .update_all(selected_for_next_round: true)
      visit rankings_path

      within('tr', text: 'Second Entry') do
        expect(next_round_checkbox(entry2)).to be_checked
        next_round_checkbox(entry2).click
      end

      within('tr', text: 'Second Entry') do
        expect(page).to have_css("#selected_for_next_round_checkbox_#{entry2.id}:not(:checked)", wait: 10)
      end
      expect(page).to have_css('.alert.alert-success', text: 'Entry selection updated successfully', wait: 5)

      expect(EntryRanking.where(entry: entry2, judging_round: judging_round, selected_for_next_round: false).count).to eq(2)
      expect(EntryRanking.where(entry: entry2, judging_round: judging_round, selected_for_next_round: true).count).to eq(0)
    end

    it 'shows judge comments when clicking view comments', :js do
      expect(page).to have_content('Internal:')
      expect(page).to have_content('External:')
    end
  end

  context 'when logged in as a judge' do
    before do
      sign_in judge1
      visit rankings_path
    end

    it 'denies access to the selection interface' do
      expect(page).to have_content('!!! Not authorized !!!')
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end
end
