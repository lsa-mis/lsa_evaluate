# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EditableContent', type: :feature do
  let!(:instructions) do
    create(:editable_content, page: 'home', section: 'instructions',
                              content: 'A short paragraph explaining LSA Evaluate.')
  end
  let(:user) { create(:user) }
  let(:admin) { create(:user) }
  let!(:role) { create(:role, kind: 'Axis mundi') }
  let!(:user_role) { create(:user_role, user: admin, role:) }

  context 'when axis_mundi is logged in' do
    before do
      login_as(admin)
      visit root_path
    end

    it 'displays the edit link with a pencil icon' do
      expect(page).to have_link('', href: editable_content_path(instructions))
      expect(page).to have_css('a[href="' + editable_content_path(instructions) + '"] .bi.bi-pencil')
    end
  end

  context 'when NON axis_mundi is logged in' do
    before do
      login_as(user)
      visit root_path
    end

    it 'does not display the edit link with a pencil icon' do
      expect(page).to have_no_link('', href: editable_content_path(instructions))
      expect(page).to have_no_css('a[href="' + editable_content_path(instructions) + '"] .bi.bi-pencil')
    end
  end

  context 'when no user is logged in' do
    before do
      visit root_path
    end

    it 'does not display the edit link with a pencil icon' do
      expect(page).to have_no_link('', href: editable_content_path(instructions))
      expect(page).to have_no_css('.bi.bi-pencil')
    end
  end
end
