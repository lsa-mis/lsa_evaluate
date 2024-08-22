# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ChooseInteractionDisplay' do
  let!(:user) { create(:user) }

  context "user not logged in" do
    it '_choose_interaction partial is not displayed' do
      visit root_path
      expect(page).to have_no_css '#opportunity-partial', visible: :visible
    end
  end

  context "user logged in" do
    it '_choose_interaction partial is displayed' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_link_or_button 'Log in'

      save_and_open_page

      expect(page).to have_current_path(root_path)
      expect(page).to have_css '#choose-interaction', visible: :visible
    end
  end

  context "logged in use is a student" do
    it 'does not see the #manage-submissions' do
      user.person_affiliation = 'student'
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_link_or_button 'Log in'

      expect(page).to have_current_path(root_path)
      expect(page).to have_no_css '#manage-submissions', visible: :visible
    end
  end
end
