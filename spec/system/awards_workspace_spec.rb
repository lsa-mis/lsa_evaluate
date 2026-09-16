# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Awards workspace', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, name: 'Hopwood') }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Poetry Award') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }
  let(:profile) do
    create(
      :profile,
      legal_first_name: 'Ada',
      legal_last_name: 'Lovelace',
      preferred_first_name: 'Ada',
      preferred_last_name: 'Lovelace'
    )
  end
  let!(:entry) { create(:entry, contest_instance: contest_instance, profile: profile, title: 'Analytical Engine') }

  before { sign_in user }

  it 'lets staff manage the catalog, assign prizes, and see them on the applicant record' do
    visit container_path(container)
    click_link 'Awards'

    expect(page).to have_current_path(container_awards_path(container))
    click_link 'Add award'

    fill_in 'Name', with: 'First Place'
    select 'Primary prize', from: 'Kind'
    fill_in 'Default amount', with: '1500'
    fill_in 'Default shortcode', with: 'P/G111'
    click_button 'Create Award'

    expect(page).to have_content('Award was successfully created.')
    expect(page).to have_content('First Place')
    expect(page).to have_content('P/G111')

    visit container_contest_description_contest_instance_path(
      container, contest_description, contest_instance, tab: 'awards'
    )

    expect(page).to have_content('Awards')
    expect(page).to have_content('Analytical Engine')
    select 'Winner', from: 'Status'
    select '1st', from: 'Placement'
    click_button 'Save outcome'

    expect(page).to have_content('Award outcome saved.')
    select 'First Place (Primary prize)', from: 'Assign prize'
    click_button 'Assign'

    expect(page).to have_content('Prize assigned.')
    expect(page).to have_field('entry_award_shortcode', with: 'P/G111')

    visit winners_container_path(container)
    expect(page).to have_content('Ada Lovelace')
    expect(page).to have_content('Winner')
    expect(page).to have_content('First Place')

    visit container_applicant_path(container, profile)
    expect(page).to have_content('Awards')
    expect(page).to have_content('First Place')
    expect(page).to have_content('Winner')
  end
end
