# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Container create contest choice modal', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }

  before { sign_in user }

  it 'opens a modal to choose one contest or bulk create when available' do
    create(:contest_description, :active, container: container)

    visit container_path(container)

    expect(page).not_to have_link('Bulk Create Contest Instances')
    click_button 'Create New Contest'

    within('#create-contest-choice-modal') do
      expect(page).to have_content('How would you like to proceed?')
      expect(page).to have_link('Create one contest', href: new_container_contest_description_path(container))
      expect(page).to have_link(
        'Bulk create contest instances',
        href: new_container_bulk_contest_instance_path(container)
      )
    end
  end
end
