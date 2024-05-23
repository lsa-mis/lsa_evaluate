# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OpportunityDisplay', type: :feature do
  it 'Opportunity partial is displayed only after user logs in' do
    visit root_path
    expect(page).not_to have_selector '#opportunity-partial', visible: true

    # Assuming there is a login path and you use Devise or similar for user authentication
    user = create(:user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'

    expect(page).to have_current_path(root_path)
    expect(page).to have_selector '#opportunity-partial', visible: true
  end
end
