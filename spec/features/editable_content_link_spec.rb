# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EditableContent' do
  let!(:description) do
    create(:editable_content, page: 'home', section: 'description',
                              content: 'A short paragraph explaining LSA Evaluate.')
  end
  let(:user) { create(:user) } # Assuming you have a user factory

  context 'when user is logged in' do
    before do
      login_as(user)
      visit root_path
    end

    it 'displays the edit link with a pencil icon' do
      expect(page).to have_link(href: editable_content_path(description)) do |link|
        expect(link).to have_css('bi bi-pencil')
      end
    end
  end

  context 'when no user is logged in' do
    before do
      visit root_path
    end

    it 'does not display the edit link with a pencil icon' do
      expect(page).to have_no_link(href: editable_content_path(description))
      expect(page).to have_no_css('bi bi-pencil')
    end
  end
end
