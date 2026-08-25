# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection user permissions', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }
  let(:admin_role) { create(:role, :collection_admin) }
  let(:admin_user) { create(:user, display_name: 'Ada Admin', uid: 'adaadmin') }

  before do
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in user
  end

  it 'shows assigned users on the collection page and manages them from collection settings' do
    visit container_path(container)

    expect(page).to have_content('Administrative users')
    expect(page).to have_content('Ada Admin (adaadmin)')
    expect(page).to have_content('Collection Administrator')
    expect(page).not_to have_content('User Permissions')
    expect(page).not_to have_button('Add User')

    click_link 'Edit Collection Settings'

    expect(page).to have_current_path(edit_container_path(container))
    expect(page).to have_content('User Permissions')
    expect(page).to have_content('Ada Admin (adaadmin)')
    expect(page).to have_button('Add User')
  end

  it 'keeps permission instructions collapsed until expanded' do
    create(:editable_content, page: 'container', section: 'permissions').tap do |record|
      record.update!(content: 'The permissions listed are for giving users access to manage this collection.')
    end

    visit edit_container_path(container)

    expect(page).to have_button('Permission instructions')
    expect(page).not_to have_css('#container-permissions-help.show')
    expect(page).not_to have_content('The permissions listed are for giving users access to manage this collection.')

    click_button 'Permission instructions'
    expect(page).to have_css('#container-permissions-help.show')
    expect(page).to have_content('The permissions listed are for giving users access to manage this collection.')
  end
end
