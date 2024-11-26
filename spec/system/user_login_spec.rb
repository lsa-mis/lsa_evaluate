require 'rails_helper'

RSpec.describe 'User login', type: :system do
  include UserCreationHelpers
  include AuthHelpers

  before do
    driven_by(:rack_test)
    OmniAuth.config.test_mode = true
  end

  it 'allows a first year student to login' do
    user = create_ugrad_student_with_profile('First year')
    mock_saml_login(user)

    visit root_path

    # Try both possible button texts
    if page.has_link?('Sign in with U-M account')
      click_link_or_button 'Sign in with U-M account'
    elsif page.has_button?('Login to LSA Evaluate')
      click_link_or_button 'Login to LSA Evaluate'
    else
      raise "Could not find login button/link. Page content: #{page.text}"
    end

    expect(page).to have_content(user.display_name)
    expect(page).to have_content('Successfully authenticated from U-M account')
  end
end
