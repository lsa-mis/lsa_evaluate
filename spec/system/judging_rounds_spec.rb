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

  describe 'special instructions' do
    it 'allows creating a round with special instructions' do
      visit new_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance
      )

      fill_in 'Round number', with: '1'

      start_date = contest_instance.date_closed + 2.days
      end_date = contest_instance.date_closed + 3.days

      fill_in 'Start date', with: start_date
      fill_in 'End date', with: end_date
      fill_in 'Special Instructions for Judges', with: 'These are special test instructions'

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
      click_link_or_button 'Manage Round Judges'
      expect(page).to have_content('These are special test instructions')
    end

    it 'displays special instructions to judges' do
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

    it 'allows editing special instructions' do
      judging_round = create(:judging_round, contest_instance: contest_instance)

      visit edit_container_contest_description_contest_instance_judging_round_path(
        container, contest_description, contest_instance, judging_round
      )

      fill_in 'Special Instructions for Judges', with: 'Updated instructions'

      # Accept the confirmation dialog
      accept_confirm do
        click_button 'Update Round'
      end

      expect(page).to have_content('Judging round was successfully updated')
      expect(page).to have_content('Updated instructions')
    end

    it 'preserves formatting in special instructions' do
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
  end
end
