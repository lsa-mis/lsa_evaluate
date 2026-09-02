# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session timeout guidance', type: :system do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }

  before do
    create(:assignment, user: user, container: container, role: admin_role)
    create(:editable_content, page: 'judging_assignments', section: 'session_timeout_guidance').tap do |record|
      record.update!(content: '<p>Judges are signed out after 2 hours of inactivity.</p>')
    end
    sign_in user
  end

  it 'shows session timeout guidance on Manage Judging' do
    visit container_contest_description_contest_instance_judging_assignments_path(
      container, contest_description, contest_instance
    )

    click_button 'Judge session timeout guidance'
    expect(page).to have_content('Judges are signed out after 2 hours of inactivity')
  end
end
