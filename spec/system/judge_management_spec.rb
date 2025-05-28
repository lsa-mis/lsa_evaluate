require 'rails_helper'

RSpec.describe 'Judge Management', type: :system do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:admin_user) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let!(:judge_role) { create(:role, kind: 'Judge') }

  before do
    # Assign admin role and create container assignment
    admin_user.roles << admin_role
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in admin_user
  end

  # Helper method to show the pool of judges tab
  def show_pool_of_judges_tab
    # Visit the page first
    visit container_contest_description_contest_instance_judging_assignments_path(
      container, contest_description, contest_instance
    )

    # Force the tab to be visible using JavaScript
    page.execute_script(<<-JS)
      var poolTab = document.getElementById('pool-of-judges');
      var roundTab = document.getElementById('round-specific');

      if (poolTab && roundTab) {
        poolTab.classList.remove('fade');
        poolTab.classList.add('show', 'active');
        roundTab.classList.remove('show', 'active');

        // Also update the tab button state
        document.querySelector('button[data-bs-target="#pool-of-judges"]').classList.add('active');
        document.querySelector('button[data-bs-target="#round-specific"]').classList.remove('active');
      }
    JS

    # Wait a moment for the DOM to update
    sleep(0.5)
  end

  describe 'creating a new judge' do
    context 'with non-umich email' do
      it 'creates a new judge with transformed email' do
        show_pool_of_judges_tab

        # Now interact with the visible tab content
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance'
          fill_in 'Email Address', with: 'newjudge@gmail.com'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-success', text: 'Judge was successfully created/updated and assigned')

        # After successful creation, visit the page again and show the tab
        show_pool_of_judges_tab

        # Now check if the newly created judge is visible in the table
        # The email should be displayed in a formatted way
        expect(page).to have_content('New Judge (newjudge@gmail.com)')

        # Verify that the new user was created with the expected email format
        new_user = User.last
        expect(new_user.email).to eq('newjudge+gmail.com@umich.edu')
        expect(new_user.roles).to include(judge_role)
      end
    end

    context 'with umich email' do
      it 'creates a new judge with original email' do
        show_pool_of_judges_tab

        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance'
          fill_in 'Email Address', with: 'newjudge@umich.edu'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-success', text: 'Judge was successfully created/updated and assigned')

        # After successful creation, visit the page again and show the tab
        show_pool_of_judges_tab

        # Now check if the newly created judge is visible in the table
        expect(page).to have_content('New Judge (newjudge@umich.edu)')

        # Verify that the new user was created with the original email
        new_user = User.last
        expect(new_user.email).to eq('newjudge@umich.edu')
      end
    end

    context 'with invalid data' do
      it 'shows validation messages' do
        initial_user_count = User.count
        show_pool_of_judges_tab

        # Try with invalid email format
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance'
          sleep(1) # Wait for animation

          fill_in 'Email Address', with: 'invalid-email'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-danger', text: 'Please enter a valid email address')
        expect(User.count).to eq(initial_user_count)

        # Try with missing required fields
        show_pool_of_judges_tab

        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance'
          sleep(1) # Wait for animation

          fill_in 'Email Address', with: ''
          fill_in 'First Name', with: ''
          fill_in 'Last Name', with: ''
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-danger', text: /required/)
        expect(User.count).to eq(initial_user_count)
      end
    end
  end

  describe 'managing existing judges' do
    let!(:existing_judge) { create(:user, email: 'judge+gmail.com@umich.edu', first_name: 'Existing', last_name: 'Judge') }

    before do
      existing_judge.roles << judge_role
      create(:judging_assignment, contest_instance: contest_instance, user: existing_judge)
    end

    it 'displays judge with formatted email' do
      show_pool_of_judges_tab

      # Check that the judge with formatted email is displayed in the table
      expect(page).to have_content('Existing Judge (judge@gmail.com)')
    end

    it 'allows removing a judge' do
      assignment = JudgingAssignment.last
      show_pool_of_judges_tab

      # Find and click the remove button, accepting the confirmation
      accept_confirm do
        click_button 'Remove'
      end

      expect(page).to have_css('.alert.alert-success', text: 'Judge assignment was successfully removed')

      # After removal, verify the assignment is gone from the database
      expect(JudgingAssignment.exists?(assignment.id)).to be false

      # Visit a different page and then come back to ensure we have a fresh view
      visit root_path
      show_pool_of_judges_tab

      # Check that there are no table rows with the judge's name
      within('table.table tbody') do
        expect(page).not_to have_content('Existing Judge')
      end
    end
  end
end
