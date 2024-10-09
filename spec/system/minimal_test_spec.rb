require 'rails_helper'

RSpec.describe 'Basic Test', type: :system do
  context 'create a user' do
    let(:user) { create(:user, :employee) }

    xit 'creates a user' do
      puts "Affiliations: #{user.affiliations.pluck(:name)}"
      expect(user).to be_persisted
    end
  end

  context 'login in as a user' do
    let(:user) { create(:user, :employee) }

    before do
      sign_in user
      # visit new_user_session_path
      # fill_in 'Email', with: user.email
      # fill_in 'Password', with: 'passwordpassword'
      # click_link_or_button 'Log in'
      # save_and_open_page
    end

    xit 'expect page to show Manage Submissions' do
      expect(page).to have_content('Manage Submissions')  # On the current page
    end
  end
end
