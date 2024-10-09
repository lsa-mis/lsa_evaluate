# spec/features/choose_interaction_spec.rb
require 'rails_helper'

RSpec.describe 'ChooseInteractionDisplay', type: :system do
  context "when user not logged in" do
    it 'does not render the _choose_interaction partial' do
      visit root_path
      expect(page).to have_content('Login to LSA Evaluate')
    end
  end

  describe 'user signed in' do
    # shared_examples 'renders the choose_interaction partial' do
    #   it 'renders the choose_interaction partial' do
    #     visit root_path
    #     sleep 5
    #     puts page.body
    #     expect(page).to have_css('[data-controller="interaction"]')
    #     expect(page).to have_css('[data-interaction-target="content"]')
    #   end
    # end

    context 'when employee user is signed in' do
      let(:user) { create(:user, :employee) }

      before do
        user
        puts user.inspect
        puts "Affiliations: #{user.affiliations.pluck(:name)}" # Ensure user is created within the transaction
        # sign_in user
        visit profiles_path
        # puts page.body
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'passwordpassword' # Ensure your factory sets a password
        click_link_or_button 'Log in'
        # sleep 5
      end

      # include_examples 'renders the choose_interaction partial'

      # it 'user has employee affiliation' do
      #   # puts "affiliations: #{user.affiliations.pluck(:name)}"
      #   expect(user.affiliations.first.name).to eq('employee')
      # end

      xit 'renders the Manage Submissions' do
        sleep 5
        # visit root_path
        puts page.body
        # expect(page).to have_css('[data-controller="interaction"]')
        # expect(page).to have_css('[data-interaction-target="content"]')
        expect(page).to have_content('Manage Submissions')
      end
    end

    context 'when student user is signed in' do
      let!(:user) { create(:user, :student) }

      before do
        user # Ensure user is created within the transaction
        # sign_in user
        visit new_user_session_path
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'passwordpassword' # Ensure your factory sets a password
        click_link_or_button 'Log in'
      end

      # include_examples 'renders the choose_interaction partial'
      xit 'renders the Submit Entry' do
        sleep 5
        visit root_path
        # sleep 5
        # puts page.body
        # expect(page).to have_css('[data-controller="interaction"]')
        # expect(page).to have_css('[data-interaction-target="content"]')
        expect(page).to have_content('Submit Entry')
      end

      xit 'does not render the Manage Submissions' do
        visit root_path
        sleep 5
        # puts page.body
        # expect(page).to have_css('[data-controller="interaction"]')
        # expect(page).to have_css('[data-interaction-target="content"]')
        expect(page).to have_content('Submit Entry')
        expect(page).to have_no_content('Manage Submissions')
      end
    end
  end
end
