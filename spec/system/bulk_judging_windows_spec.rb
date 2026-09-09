# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk judging windows', type: :system do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let!(:round_one) do
    create(:judging_round,
           contest_instance: contest_instance,
           round_number: 1,
           active: true,
           start_date: contest_instance.date_closed + 1.day,
           end_date: contest_instance.date_closed + 10.days)
  end

  before { sign_in user }

  it 'extends a judging round end date from the collection page' do
    visit new_container_bulk_judging_window_path(container)

    expect(page).to have_content('Bulk Update Judging Windows')
    expect(page).to have_content(contest_description.name)

    new_end_date = (round_one.end_date + 3.days).strftime('%Y-%m-%dT%H:%M')
    page.execute_script(<<~JS)
      document.getElementById('judging_round_#{round_one.id}').checked = true;
      document.getElementById('bulk_judging_window_form_end_date').value = '#{new_end_date}';
    JS

    click_button 'Update Judging Windows'

    expect(page).to have_current_path(container_path(container))
    expect(round_one.reload.end_date).to eq(Time.zone.parse(new_end_date))
  end
end
