# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ChooseInteractionDisplay' do
  it '_choose_interaction partial is displayed only after user logs in' do
    visit root_path
    expect(page).to have_no_css '#opportunity-partial', visible: :visible

    # Assuming there is a login path and you use Devise or similar for user authentication
    user = create(:user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_link_or_button 'Log in'

    expect(page).to have_current_path(root_path)
    expect(page).to have_css '#choose_interaction', visible: :visible
  end
end
