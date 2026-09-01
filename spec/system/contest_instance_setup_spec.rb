# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contest instance setup', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'War of 1812 Research') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:question) { container.application_questions.find_by!(system_key: 'pen_name') }

  before { sign_in user }

  def questions_path
    setup_questions_container_contest_description_contest_instance_path(
      container, contest_description, contest_instance
    )
  end

  def review_process_path
    setup_review_process_container_contest_description_contest_instance_path(
      container, contest_description, contest_instance
    )
  end

  def instance_path
    container_contest_description_contest_instance_path(
      container, contest_description, contest_instance
    )
  end

  it 'saves question overrides and continues to the review process step' do
    visit questions_path

    expect(page).to have_content('Review questions')
    expect(page).to have_css('.setup-stepper-item--current', text: 'Questions')
    expect(page).not_to have_content('Save this contest instance first')

    select 'Required', from: "requirements_#{question.id}_status"
    click_button 'Save and continue'

    expect(page).to have_current_path(review_process_path)
    expect(page).to have_content('Review process')
    expect(contest_instance.application_question_requirements.find_by!(application_question: question).status)
      .to eq('required')
  end

  it 'skips questions without writing instance-level requirements' do
    visit questions_path

    expect {
      click_link 'Skip'
    }.not_to change(ApplicationQuestionRequirement, :count)

    expect(page).to have_current_path(review_process_path)
    expect(contest_instance.application_question_requirements).to be_empty
  end

  it 'skips the review process and lands on the instance dashboard' do
    visit review_process_path

    click_link 'Skip'

    expect(page).to have_current_path(instance_path)
    expect(page).to have_content(contest_description.name)
  end

  it 'creates a judging round during setup and continues to the dashboard' do
    visit review_process_path

    start_date = contest_instance.date_closed + 1.day
    end_date = contest_instance.date_closed + 2.days

    fill_in 'Round number', with: '1'
    fill_in 'Number of Entries to be Selected', with: '3'
    page.execute_script(
      "document.getElementById('judging_round_start_date').value = #{start_date.strftime('%Y-%m-%dT%H:%M').to_json}"
    )
    page.execute_script(
      "document.getElementById('judging_round_end_date').value = #{end_date.strftime('%Y-%m-%dT%H:%M').to_json}"
    )
    fill_in 'Instructions for Judges', with: 'Rank the top entries.'

    click_button 'Save and continue'

    expect(page).to have_current_path(instance_path)
    expect(contest_instance.judging_rounds.last.special_instructions).to eq('Rank the top entries.')
    expect(contest_instance.judging_rounds.last.required_entries_count).to eq(3)
  end

  it 'does not show the grey save-first note on the new instance form' do
    visit new_container_contest_description_contest_instance_path(container, contest_description)

    expect(page).to have_content('New contest instance')
    expect(page).to have_css('.setup-stepper-item--current', text: 'Contest details')
    expect(page).not_to have_content('Save this contest instance first')
  end

  it 'still shows the requirements matrix when editing an instance' do
    visit edit_container_contest_description_contest_instance_path(
      container, contest_description, contest_instance
    )

    expect(page).to have_content('Application Question Requirements')
  end
end
