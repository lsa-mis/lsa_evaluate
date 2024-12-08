require 'rails_helper'

RSpec.describe 'Judge login', type: :system do
  include AuthHelpers

  before do
    driven_by(:rack_test)
    OmniAuth.config.test_mode = true
  end

  describe 'login workflow' do
    context 'when user is a judge' do
      let(:judge) { create(:user, :with_judge_role) }

      it 'redirects to judge dashboard after login' do
        mock_saml_login(judge)
        visit root_path

        click_button 'Login to LSA Evaluate'

        expect(page).to have_current_path(judge_dashboard_path)
        expect(page).to have_content('Successfully authenticated from U-M account')
        expect(page).to have_content(judge.uniqname)
      end
    end

    context 'when user is not a judge' do
      let(:regular_user) { create(:user) }

      it 'redirects to root path after login' do
        mock_saml_login(regular_user)
        visit root_path

        click_button 'Login to LSA Evaluate'

        expect(page).to have_current_path(root_path)
        expect(page).to have_content('Successfully authenticated from U-M account')
        expect(page).to have_content(regular_user.display_name)
      end
    end
  end
end
