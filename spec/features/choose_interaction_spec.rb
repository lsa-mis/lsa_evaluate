# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ChooseInteractionDisplay', type: :system do
  context "when user not logged in" do
    it 'does not render the _choose_interaction partial' do
      visit root_path
      expect(page).to have_no_css '#opportunity-partial', visible: :visible
    end
  end

  describe 'user signed in' do
    shared_examples 'renders the choose_interaction partial' do
      it 'renders the choose_interaction partial' do
        get root_path
        expect(response.body).to include('data-controller="interaction"')
        expect(response.body).to include('data-interaction-target="content"')
      end
    end

    context 'when employee user is signed in' do
      let!(:user) { create(:user, :employee) }

      before do
        mock_login({
                     email: user.email,
                     name: user.display_name,
                     uniqname: user.uniqname
                   })
        get root_path
      end

      include_examples 'renders the choose_interaction partial'

      it 'renders the manage-submissions' do
        expect(response.body).to include('manage-submissions')
      end
    end

    context 'when student user is signed in' do
      let!(:user) { create(:user, :student) }

      before do
        mock_login({
                     email: user.email,
                     name: user.display_name,
                     uniqname: user.uniqname
                   })
        get root_path
      end

      include_examples 'renders the choose_interaction partial'

      it 'does not render the manage-submissions' do
        expect(response.body).not_to include('manage-submissions')
      end
    end
  end
end
