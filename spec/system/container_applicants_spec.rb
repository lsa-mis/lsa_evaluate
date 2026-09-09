# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection applicant directory', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, name: 'Hopwood') }
  let(:ann_arbor) { create(:campus, campus_descr: 'Ann Arbor') }
  let(:dearborn) { create(:campus, campus_descr: 'Dearborn') }
  let(:poetry) { create(:contest_description, :active, container: container, name: 'Poetry Award') }
  let(:instance) { create(:contest_instance, contest_description: poetry, active: true) }

  def create_applicant!(legal_last_name:, legal_first_name:, campus:)
    profile = create(
      :profile,
      legal_last_name: legal_last_name,
      legal_first_name: legal_first_name,
      preferred_last_name: legal_last_name,
      preferred_first_name: legal_first_name,
      campus: campus
    )
    create(:entry, contest_instance: instance, profile: profile, title: "#{legal_first_name} submission")
    profile
  end

  before { sign_in user }

  it 'opens the applicant list from the collection and searches by name and campus' do
    ada = create_applicant!(legal_last_name: 'Lovelace', legal_first_name: 'Ada', campus: ann_arbor)
    create_applicant!(legal_last_name: 'Manager', legal_first_name: 'Moe', campus: dearborn)

    visit container_path(container)

    expect(page).to have_content('Unique Submitters: 2')
    click_link 'Applicants'

    expect(page).to have_current_path(container_applicants_path(container))
    expect(page).to have_content('Unique submitters')
    expect(page).to have_content(ada.display_name)
    expect(page).to have_content('Moe Manager')
    expect(page).to have_content('Poetry Award')

    fill_in 'Name', with: 'Lovelace'
    click_button 'Filter'

    expect(page).to have_content(ada.display_name)
    expect(page).not_to have_content('Moe Manager')

    click_link 'Clear'
    select 'Dearborn', from: 'Campus'
    click_button 'Filter'

    expect(page).to have_content('Moe Manager')
    expect(page).not_to have_content(ada.display_name)

    click_link 'Clear'
    click_link ada.display_name

    expect(page).to have_current_path(container_applicant_path(container, ada))
    expect(page).to have_content('All Submissions')
    expect(page).to have_content('Poetry Award')
    expect(page).to have_content('Ann Arbor')
  end
end
