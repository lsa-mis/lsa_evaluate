# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navbar dropdown', type: :system do
  def open_avatar_menu
    find('#avatar').click
    expect(page).to have_css('#avatar-menu.show')
  end

  describe 'Admin Dashboard link visibility' do
    let(:regular_user) { create(:user) }
    let(:judge) { create(:user, :with_judge_role) }
    let(:manager) { create(:user, :with_collection_manager_role) }
    let(:administrator) { create(:user, :with_collection_admin_role) }
    let(:axis_mundi_user) { create(:user, :axis_mundi) }

    it 'does not show Admin Dashboard to regular users' do
      sign_in regular_user
      visit root_path
      open_avatar_menu

      expect(page).not_to have_button('Admin Dashboard')
    end

    it 'does not show Admin Dashboard to judges without admin role' do
      sign_in judge
      visit root_path
      open_avatar_menu

      expect(page).not_to have_button('Admin Dashboard')
    end

    it 'does not show Admin Dashboard to managers without admin role' do
      sign_in manager
      visit root_path
      open_avatar_menu

      expect(page).not_to have_button('Admin Dashboard')
    end

    it 'shows Admin Dashboard to Collection Administrators' do
      sign_in administrator
      visit root_path
      open_avatar_menu

      expect(page).to have_button('Admin Dashboard')
    end

    it 'shows Admin Dashboard to Axis Mundi users' do
      sign_in axis_mundi_user
      visit root_path
      open_avatar_menu

      expect(page).to have_button('Admin Dashboard')
    end

    it 'links Admin Dashboard to contest collections' do
      sign_in axis_mundi_user
      visit root_path
      open_avatar_menu
      click_button 'Admin Dashboard'

      expect(page).to have_current_path(containers_path)
      expect(page).to have_content('Manage Contest Collections')
    end
  end
end
