require 'rails_helper'

RSpec.describe "Drag and Drop", :js, type: :system do
  let(:user) { create(:user, :with_judge_role) }
  let(:contest_instance) { create(:contest_instance) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance, active: true) }
  let(:judging_assignment) { create(:judging_assignment, user: user, contest_instance: contest_instance) }
  let!(:entries) { create_list(:entry, 3, contest_instance: contest_instance) }

  before do
    sign_in user
    judging_round # ensure it's created
    judging_assignment # ensure it's created
  end

  it "allows a judge to drag and drop entries" do
    visit judge_dashboard_path

    # Find and click the accordion button for this contest
    find('.accordion-button', text: contest_instance.contest_description.name).click

    # Wait for accordion to expand
    expect(page).to have_css('.accordion-collapse.show')

    # Find the first entry card and its drag handle
    entry_card = find('.entry-card', match: :first)
    drag_handle = entry_card.find('.drag-handle')

    # Find the rated entries section
    rated_entries = find("[data-entry-drag-target='ratedEntries']")

    # Perform the drag and drop
    drag_handle.drag_to(rated_entries)

    # Wait for the AJAX request to complete
    sleep 1

    # Verify the entry was moved
    within "[data-entry-drag-target='ratedEntries']" do
      expect(page).to have_css('.entry-card', count: 1)
    end

    within "[data-entry-drag-target='availableEntries']" do
      expect(page).to have_css('.entry-card', count: 2)
    end
  end
end
