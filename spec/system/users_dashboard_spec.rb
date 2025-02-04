# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users Dashboard', type: :system do
  let!(:axis_mundi_user) { create(:user, :axis_mundi) }
  let!(:regular_user) { create(:user) }

  context 'when logged in as axis mundi user' do
    before do
      driven_by(:selenium_chrome_headless)
      login_as axis_mundi_user
      visit users_dashboard_index_path
    end

    it 'displays the users table' do
      expect(page).to have_content('Users Dashboard')
      expect(page).to have_content(regular_user.email)
    end

    it 'allows sorting by principal name' do
      expect(page).to have_link('Principal Name')
      click_on 'Principal Name'
      expect(page).to have_current_path(/#{users_dashboard_index_path}.*/)
      expect(page).to have_current_path(/sort=principal_name/, wait: 5)
      expect(current_url).to include('direction=asc')
    end

    it 'allows viewing user details' do
      click_link 'View', match: :first
      expect(page).to have_content('User Details')
      expect(page).to have_content('Basic Information')
      expect(page).to have_content('Authentication Details')
    end

    it 'shows pagination when there are many users' do
      create_list(:user, 25)  # Create more than one page worth of users
      visit users_dashboard_index_path
      expect(page).to have_css('.pagination')
    end
  end

  context 'when logged in as regular user' do
    before do
      driven_by(:selenium_chrome_headless)
      sign_in regular_user
    end

    it 'prevents access to the dashboard' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(root_path, ignore_query: true)
      expect(page).to have_content(/not authorized/i)
    end

    it 'prevents access to user details' do
      visit users_dashboard_path(axis_mundi_user)
      expect(page).to have_current_path(root_path, ignore_query: true)
      expect(page).to have_content(/not authorized/i)
    end
  end

  context 'when not logged in' do
    before do
      driven_by(:selenium_chrome_headless)
    end

    it 'redirects to login page' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end
  end
end
