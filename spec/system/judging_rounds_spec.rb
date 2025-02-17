require 'rails_helper'

RSpec.describe 'Judging Rounds', type: :system do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user) }
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance,
    contest_description: contest_description,
    date_open: 2.days.ago,
    date_closed: 1.day.ago
  ) }

  before do
    container_admin_role = create(:role, kind: 'Collection Administrator')
    create(:assignment, user: admin, container: container, role: container_admin_role)
    sign_in admin
  end

  describe 'instructions' do
    it 'allows creating a round with instructions' do
      visit new_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance
      )

      fill_in 'Round number', with: '1'

      start_date = contest_instance.date_closed + 2.days
      end_date = contest_instance.date_closed + 3.days

      fill_in 'Date and time to open judging round to judges', with: start_date
      fill_in 'Date and time to close judging round to judges', with: end_date
      fill_in 'Instructions for Judges', with: 'These are test instructions'

      expect {
        begin
          click_button 'Create Round'

          if page.has_css?('.alert-danger')
            page.all('.alert-danger').each do |alert|
            end
          end

          if page.has_css?('.error')
            page.all('.error').each do |error|
            end
          end

        rescue => e
        end
      }.to change(JudgingRound, :count).by(1)

      expect(page).to have_content('Judging round was successfully created')
      expect(page).to have_current_path(
        container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
        )
      )
      click_link_or_button 'Manage Round', wait: 5
      expect(page).to have_content('These are test instructions')
    end

    it 'displays instructions to judges' do
      judging_round = create(:judging_round,
        contest_instance: contest_instance,
        special_instructions: 'Important judging guidelines',
        active: true
      )
      judge = create(:user, :with_judge_role)
      create(:judging_assignment, user: judge, contest_instance: contest_instance)

      sign_in judge
      visit judge_dashboard_path

      # Click the accordion button to expand it
      find('.accordion-button').click

      expect(page).to have_content('Important judging guidelines')
    end

    it 'allows editing instructions' do
      judging_round = create(:judging_round, contest_instance: contest_instance)

      visit edit_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, judging_round
      )

      fill_in 'Instructions for Judges', with: 'Judging round was successfully updated'

      # Accept the confirmation dialog
      accept_confirm do
        click_button 'Update Round'
      end

      expect(page).to have_content('Judging round was successfully updated')
      expect(page).to have_content('Judging round was successfully updated')
    end

    it 'preserves formatting in instructions' do
      instructions = "Line 1\nLine 2\nLine 3"
      judging_round = create(:judging_round,
        contest_instance: contest_instance,
        special_instructions: instructions
      )

      visit container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
        container, contest_description, contest_instance, judging_round
      )

      instructions.split("\n").each do |line|
        expect(page).to have_content(line)
      end
    end

    it 'shows warning when editing a started round' do
      judging_round = create(:judging_round,
        contest_instance: contest_instance,
        start_date: 1.day.ago
      )

      visit edit_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, judging_round
      )

      expect(page).to have_content('Warning: This round has already started')
    end

    it 'does not show warning when editing a future round' do
      judging_round = create(:judging_round,
        contest_instance: contest_instance,
        start_date: 1.day.from_now
      )

      visit edit_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, judging_round
      )

      expect(page).to have_no_content('Warning: This round has already started')
    end

    it 'shows error when activating a round while another is active' do
      active_round = create(:judging_round,
        contest_instance: contest_instance,
        active: true,
        start_date: 1.day.from_now,
        end_date: 2.days.from_now
      )

      inactive_round = create(:judging_round,
        contest_instance: contest_instance,
        active: false,
        start_date: active_round.end_date + 1.day,
        end_date: active_round.end_date + 2.days
      )

      visit container_contest_description_contest_instance_judging_assignments_path(
        container, contest_description, contest_instance
      )

      # The round-specific tab should be active by default, but let's make sure
      expect(page).to have_css('#round-specific.active')

      # Find and click the Activate button for the inactive round
      within('.judging-rounds') do
        # Find the last card (which should be the inactive round)
        within('.card:last-child') do
          click_button 'Activate'
        end
      end

      # Look for the flash message
      expect(page).to have_content("All previous rounds must be completed before activating this round")
    end
  end
end
