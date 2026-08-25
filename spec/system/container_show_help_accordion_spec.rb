# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Container show help accordions', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }

  before { sign_in user }

  it 'expands and collapses section help text from the info buttons' do
    visit container_path(container)

    expect(page).not_to have_css('#entries-summary-help.show')
    expect(page).not_to have_css('#contests-in-collection-help.show')

    click_button 'About Entries Summary'
    expect(page).to have_css('#entries-summary-help.show')
    expect(page).to have_content('Summary of active entries across all active contests in this collection')

    click_button 'About Entries Summary'
    expect(page).not_to have_css('#entries-summary-help.show')

    click_button 'About Contest within this Collection'
    expect(page).to have_css('#contests-in-collection-help.show')
    expect(page).to have_content('Summary of contests within this collection')
  end
end
