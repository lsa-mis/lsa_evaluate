# spec/system/homepage_navigation_spec.rb
require 'rails_helper'

RSpec.describe 'Homepage Navigation', type: :system do
  before do
    driven_by(:rack_test)
  end

  context 'when user is not signed in' do
    before do
      visit root_path
    end

    it 'renders the home template' do
      expect(page).to have_http_status(:ok)
      expect(page).to have_current_path(root_path)
    end

    it 'does not render the choose_interaction partial' do
      expect(page).not_to have_css('[data-controller="interaction"]')
      expect(page).not_to have_css('[data-interaction-target="content"]')
    end
  end

  context 'when user is signed in' do
    let(:user) { create(:user) }

    before do
      sign_in user
      visit root_path
    end

    it 'renders the choose_interaction partial' do
      expect(page).to have_css('[data-controller="interaction"]')
      expect(page).to have_css('[data-interaction-target="content"]')
    end

    it 'features the applicants card and hides contest administrator content' do
      expect(page).to have_css('#student-submit-entry .card')
      expect(page).not_to have_css('#manage-submissions .card')
      expect(page).not_to have_link('Contest Administrators')
    end
  end

  context 'when user has specific roles' do
    let(:regular_user) { create(:user) }
    let(:employee) { create(:user, :employee) }
    let(:administrator) { create(:user, :with_collection_admin_role) }
    let(:manager) { create(:user, :with_collection_manager_role) }
    let(:axis_mundi_user) { create(:user, :axis_mundi) }

    it 'does not show the Contest Administrators button to regular users' do
      sign_in regular_user
      visit root_path
      expect(page).not_to have_link('Contest Administrators')
    end

    it 'shows the Contest Administrators button to campus employees' do
      sign_in employee
      visit root_path
      expect(page).to have_link('Contest Administrators', href: containers_path)
      expect(page).not_to have_css('#manage-submissions .card')
    end

    it 'shows the Contest Administrators button to collection managers' do
      sign_in manager
      visit root_path
      expect(page).to have_link('Contest Administrators', href: containers_path)
    end

    it 'shows the Contest Administrators button to collection administrators' do
      sign_in administrator
      visit root_path
      expect(page).to have_link('Contest Administrators', href: containers_path)
    end

    it 'shows the Contest Administrators button to Axis Mundi users' do
      sign_in axis_mundi_user
      visit root_path
      expect(page).to have_link('Contest Administrators', href: containers_path)
    end
  end
end
