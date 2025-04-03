# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users Dashboard', type: :system do
  let!(:axis_mundi_user) { create(:user, :axis_mundi) }
  let!(:regular_user) { create(:user) }
  let!(:judge_user) { create(:user, :with_judge_role) }
  let!(:admin_user) { create(:user, :with_collection_admin_role) }
  let!(:manager_user) { create(:user, :with_collection_manager_role) }
  let!(:multi_role_user) { create(:user, :with_judge_role, :with_collection_admin_role, :with_collection_manager_role) }

  # Test data for filtering
  let!(:user_abc) { create(:user, principal_name: 'abc123', email: 'abc123@example.com') }
  let!(:user_def) { create(:user, principal_name: 'def456', email: 'def456@example.com') }
  let!(:user_abc_alt) { create(:user, principal_name: 'abc789', email: 'xyz@example.com') }

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

    describe 'filtering functionality' do
      it 'filters users by principal name' do
        fill_in 'Principal Name:', with: 'abc'
        click_button 'Filter'

        expect(page).to have_content('abc123')
        expect(page).to have_content('abc789')
        expect(page).not_to have_content('def456')
      end

      it 'filters users by email' do
        fill_in 'Email:', with: 'def'
        click_button 'Filter'

        expect(page).to have_content('def456@example.com')
        expect(page).not_to have_content('abc123@example.com')
        expect(page).not_to have_content('xyz@example.com')
      end

      it 'filters users by both principal name and email' do
        fill_in 'Principal Name:', with: 'abc'
        fill_in 'Email:', with: 'xyz'
        click_button 'Filter'

        expect(page).to have_content('abc789')
        expect(page).to have_content('xyz@example.com')
        expect(page).not_to have_content('abc123')
        expect(page).not_to have_content('def456')
      end

      it 'preserves filters when sorting' do
        fill_in 'Principal Name:', with: 'abc'
        click_button 'Filter'

        expect(page).to have_content('abc123')
        expect(page).to have_content('abc789')

        click_on 'Email'

        expect(page).to have_content('abc123')
        expect(page).to have_content('abc789')
        expect(page).not_to have_content('def456')
        expect(current_url).to include('principal_name_filter=abc')
      end

      it 'clears filters when clicking Clear button' do
        fill_in 'Principal Name:', with: 'abc'
        click_button 'Filter'

        expect(page).to have_content('abc123')
        expect(page).not_to have_content('def456')

        click_link 'Clear'

        expect(page).to have_content('abc123')
        expect(page).to have_content('def456')
        expect(page).not_to have_current_path(/principal_name_filter/)
      end
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

  context 'when user has Judge role' do
    before do
      sign_in judge_user
    end

    it 'prevents access to the dashboard' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content(/not authorized/i)
    end
  end

  context 'when user has Collection Administrator role' do
    before do
      sign_in admin_user
    end

    it 'prevents access to the dashboard' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content(/not authorized/i)
    end
  end

  context 'when user has Collection Manager role' do
    before do
      sign_in manager_user
    end

    it 'prevents access to the dashboard' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content(/not authorized/i)
    end
  end

  context 'when user has multiple roles but not Axis Mundi' do
    let(:multi_role_user) { create(:user) }

    before do
      sign_in multi_role_user
    end

    it 'prevents access to the dashboard' do
      visit users_dashboard_index_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content(/not authorized/i)
    end
  end
end
