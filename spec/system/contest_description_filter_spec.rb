require 'rails_helper'

RSpec.describe 'Contest Description Filter' do
  let(:container) { create(:container) }
  let(:active_description) { create(:contest_description, container: container, active: true, archived: false) }
  let(:inactive_description) { create(:contest_description, container: container, active: false, archived: false) }

  before do
    # Create the user with the nested affiliations
    user2 = User.create!(
      email: 'bobstaff@example.com',
      password: 'passwordpassword',
      uniqname: 'bobstaff',
      uid: 'bobstaff',
      principal_name: 'bobstaff@example.com',
      display_name: 'Bob Builder',
      affiliations_attributes: [
        { name: 'staff' },
        { name: 'employee' },
        { name: 'member' }
      ]
    )

    # Log in programmatically using Warden
    login_as(user2, scope: :user)
  end

  context 'when the filter is unchecked' do
    xit 'shows all contest descriptions when the filter is unchecked' do
      # Visit the container path after login
      visit container_path(container)

      # Check for both active and inactive contest descriptions
      expect(page).to have_content(active_description.name)
      expect(page).to have_content(inactive_description.name)
    end
  end

  context 'when the filter is checked' do
    xit 'only shows active contest descriptions when the filter is checked' do
      visit container_path(container)

      # Check the checkbox to filter active descriptions
      check 'statusFilter'

      # Verify that the active description is shown
      expect(page).to have_content(active_description.name)

      # Verify that the inactive description is hidden
      expect(page).not_to have_content(inactive_description.name)
    end
  end
end
