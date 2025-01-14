require 'rails_helper'

RSpec.describe 'Judge Management', type: :system do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
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

  describe 'creating a new judge' do
    before do
      visit container_contest_description_contest_instance_judging_assignments_path(
        container, contest_description, contest_instance
      )
    end

    context 'with non-umich email' do
      it 'creates a new judge with transformed email' do
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance' # expand the accordion
          fill_in 'Email Address', with: 'newjudge@gmail.com'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-success', text: 'Judge was successfully created/updated and assigned')
        expect(page).to have_content('New Judge (newjudge@gmail.com)')

        new_user = User.last
        expect(new_user.email).to eq('newjudge+gmail.com@umich.edu')
        expect(new_user.roles).to include(judge_role)
      end
    end

    context 'with umich email' do
      it 'creates a new judge with original email' do
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance' # expand the accordion
          fill_in 'Email Address', with: 'newjudge@umich.edu'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-success', text: 'Judge was successfully created/updated and assigned')
        expect(page).to have_content('New Judge (newjudge@umich.edu)')

        new_user = User.last
        expect(new_user.email).to eq('newjudge@umich.edu')
      end
    end

    context 'with invalid data' do
      it 'shows validation messages' do
        initial_user_count = User.count

        # Try with invalid email format
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance' # expand the accordion
          sleep(1) # Wait for animation

          fill_in 'Email Address', with: 'invalid-email'
          fill_in 'First Name', with: 'New'
          fill_in 'Last Name', with: 'Judge'
          click_button 'Create and Assign Judge'
        end

        expect(page).to have_css('.alert.alert-danger', text: 'Please enter a valid email address')
        expect(User.count).to eq(initial_user_count)

        # Try with missing required fields
        within('#createJudgeAccordion') do
          click_button 'Create a new judge and assign them to the pool of judges for this contest instance' # expand the accordion again
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
      visit container_contest_description_contest_instance_judging_assignments_path(
        container, contest_description, contest_instance
      )
    end

    it 'displays judge with formatted email' do
      within('.card', text: /Pool of judges assigned to this contest instance/i) do
        within('table') do
          expect(page).to have_content('Existing Judge (judge@gmail.com)')
        end
      end
    end

    it 'allows removing a judge' do
      assignment = JudgingAssignment.last

      within('.card', text: /Pool of judges assigned to this contest instance/i) do
        within('table') do
          accept_confirm do
            click_button 'Remove'
          end
        end
      end

      expect(page).to have_css('.alert.alert-success', text: 'Judge assignment was successfully removed')

      # Verify the judge is no longer in the current judges table
      within('.card', text: /Pool of judges assigned to this contest instance/i) do
        within('table tbody') do
          expect(page).to have_no_content('Existing Judge')
        end
      end

      expect(JudgingAssignment.exists?(assignment.id)).to be false
    end
  end
end
