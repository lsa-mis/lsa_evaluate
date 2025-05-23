# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EditableContent', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:instructions) do
    create(:editable_content, page: 'home', section: 'instructions')
  end
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, :axis_mundi) }

  context 'when axis_mundi is logged in' do
    before do
      login_as(admin)
      visit root_path
    end

    it 'displays the edit link' do
      expect(page).to have_link('', href: edit_editable_content_path(instructions))
    end

    it 'displays a pencil icon within the edit link' do
      expect(page).to have_css('a.edit-link i.bi.bi-pencil')
    end
  end

  context 'when non axis_mundi user is logged in' do
    before do
      login_as(user)
      visit root_path
    end

    it 'does not display the edit link' do
      expect(page).to have_no_link('', href: edit_editable_content_path(instructions))
    end

    it 'does not display a pencil icon within the edit link' do
      expect(page).to have_no_css('a.edit-link i.bi.bi-pencil')
    end
  end

  context 'when no user is logged in' do
    before do
      visit root_path
    end

    it 'does not display the edit link' do
      expect(page).to have_no_link('', href: edit_editable_content_path(instructions))
    end

    it 'does not display a pencil icon' do
      expect(page).to have_no_css('.bi.bi-pencil')
    end
  end
end
