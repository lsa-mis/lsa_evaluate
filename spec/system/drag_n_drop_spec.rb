require 'rails_helper'

RSpec.describe "Drag and Drop", :js, type: :system do
    before do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  let!(:user) { create(:user, :with_judge_role) }
  let!(:contest_instance) { create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago) }
  let!(:judging_assignment) { create(:judging_assignment, user: user, contest_instance: contest_instance) }
  let!(:judging_round) { create(:judging_round, contest_instance: contest_instance, active: true) }
  let!(:round_judge_assignment) { create(:round_judge_assignment, judging_round: judging_round, user: user) }
  let!(:entries) { create_list(:entry, 1, contest_instance: contest_instance) }
  let!(:contest_instance_element) { PageObjects::ContestInstanceElement.new(page, contest_instance) }

  before do
    sign_in user
  end

  it "allows a judge to drag and drop entries" do
    visit judge_dashboard_path

    # Find and click the accordion button for this contest
    # find('.accordion-button', text: contest_instance.contest_description.name).click
    contest_instance_element.expand

    sleep 1

    # Wait for accordion to expand and content to be visible
    expect(contest_instance_element.expanded?).to be true

    sleep 1

    expect(page).to have_css('.drag-handle')

    # Find the first entry card with its drag handle
    entry_card = find('.card[data-entry-id]', match: :first, wait: 5)
    contest_instance_element.drag_entry_card_to_rated_entries_area(entry_card)

    # Verify the entry was moved
    within contest_instance_element.rated_entries_area do
      expect(contest_instance_element.entry_card_count).to eq(1)
    end

    within contest_instance_element.available_entries_area do
      expect(contest_instance_element.entry_card_count).to eq(0)
    end
  end
end
