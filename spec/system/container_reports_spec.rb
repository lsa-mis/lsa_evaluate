# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection reports', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }

  before { sign_in user }

  it 'opens the reports page from Generate Reports and keeps reports off the collection page' do
    contest_description = create(:contest_description, :active, container: container, name: 'First contest in the new collection')

    visit container_path(container)

    expect(page).to have_link('Generate Reports', href: reports_container_path(container))
    expect(page).not_to have_css('#reports')
    expect(page).not_to have_content('Active Applicants Report')
    expect(page).not_to have_button('Generate - Download Report')

    click_link 'Generate Reports'

    expect(page).to have_current_path(reports_container_path(container))
    expect(page).to have_content('Reports')
    expect(page).to have_content('Active Applicants Report')
    expect(page).to have_content(contest_description.name)
    expect(page).to have_button('Generate - Download Report')

    click_link 'Return to Manage Collection'
    expect(page).to have_current_path(container_path(container))
  end
end
