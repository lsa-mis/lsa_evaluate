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
  end
end
