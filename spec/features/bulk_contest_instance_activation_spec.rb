# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Contest Instance Activation', type: :feature do
  let(:container) { create(:container) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:admin) { create(:user) }
  let(:description) { create(:contest_description, :active, container: container) }
  let!(:existing_instance) do
    create(
      :contest_instance,
      contest_description: description,
      active: true,
      date_open: 2.months.ago,
      date_closed: 1.month.ago
    )
  end

  before do
    create(:assignment, container: container, user: admin, role: admin_role)
    login_as admin
  end

  it 'prompts activation after bulk create and activates the newest season' do
    new_open_date = 1.month.from_now
    new_close_date = 2.months.from_now

    visit new_container_bulk_contest_instance_path(container)
    check "contest_description_#{description.id}"
    fill_in 'bulk_contest_instance_form[date_open]', with: new_open_date.strftime('%Y-%m-%dT00:00')
    fill_in 'bulk_contest_instance_form[date_closed]', with: new_close_date.strftime('%Y-%m-%dT00:00')
    click_button 'Create Instances'

    expect(page).to have_content('Bulk Activate Contest Instances')
    expect(page).to have_content(description.name)

    check 'bulk_activation_confirmed'
    click_button 'Activate season'

    expect(page).to have_content('Contest instances were successfully activated.')
    expect(page).to have_content('Bulk activation report')
    expect(page).to have_content(description.name)

    newest = description.contest_instances.order(:created_at).last
    expect(newest.reload).to be_active
    expect(existing_instance.reload).not_to be_active
  end
end
