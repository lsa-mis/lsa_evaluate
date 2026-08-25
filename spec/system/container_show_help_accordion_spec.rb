# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Container show help accordions', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }
  let!(:container_information) do
    create(:editable_content, page: 'container', section: 'information').tap do |record|
      record.update!(content: 'The collection is the container of all the contests you want to run.')
    end
  end

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

    click_button "About #{container.name} Contests"
    expect(page).to have_css('#contests-in-collection-help.show')
    expect(page).to have_content('Summary of contests within this collection')
  end

  it 'keeps collection instructions collapsed until an admin expands them' do
    visit container_path(container)

    expect(page).to have_button('Collection instructions')
    expect(page).not_to have_css('#container-information-help.show')
    expect(page).not_to have_content('The collection is the container of all the contests you want to run.')

    click_button 'Collection instructions'
    expect(page).to have_css('#container-information-help.show')
    expect(page).to have_content('The collection is the container of all the contests you want to run.')
    expect(page).to have_link('', href: edit_editable_content_path(container_information))

    click_button 'Collection instructions'
    expect(page).not_to have_css('#container-information-help.show')
    expect(page).not_to have_content('The collection is the container of all the contests you want to run.')
  end
end
