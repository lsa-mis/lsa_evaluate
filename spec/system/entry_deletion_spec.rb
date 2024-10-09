# spec/system/entry_deletion_spec.rb
require 'rails_helper'

RSpec.describe 'Entry deletion', type: :system, js: true do
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user: user) }
  let(:contest_instance) { create(:contest_instance, date_closed: date_closed) }
  let!(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

  before do
    puts "Current Capybara driver: #{Capybara.current_driver}"
    sign_in user
  end

  context 'when the contest instance is still open' do
    let(:date_closed) { 1.day.from_now }

    xit 'shows the delete link and allows deletion' do
      visit applicant_dashboard_path
      # puts page.body
      # Verify that the entry exists
      expect(Entry.exists?(entry.id)).to be true

      expect(page).to have_selector("a[href='#{soft_delete_entry_path(entry)}']")

      # Simulate clicking the delete link
      accept_confirm 'Are you sure you want to remove this entry?' do
        click_link href: soft_delete_entry_path(entry)
      end

      expect(page).to have_content('Entry was successfully removed.')
      expect(page).not_to have_content(entry.title)
    end
  end

  context 'when the contest instance has closed' do
    let(:date_closed) { 1.day.ago }

    xit 'does not show the delete link' do
      visit applicant_dashboard_path

      expect(page).not_to have_selector("a[href='#{soft_delete_entry_path(entry)}']")
      # Optionally check for the disabled icon
      expect(page).to have_selector('i.bi.bi-file-x-fill.disabled')
    end
  end
end
