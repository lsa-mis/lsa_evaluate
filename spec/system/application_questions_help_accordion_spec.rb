# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application questions help accordion', type: :system do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container) }
  let!(:instructions) do
    create(:editable_content, page: 'application_questions', section: 'instructions').tap do |record|
      record.update!(content: 'Department shows for graduate class levels; Major for undergraduate.')
    end
  end

  before { sign_in user }

  it 'keeps application question instructions collapsed until an admin expands them' do
    visit container_application_questions_path(container)

    expect(page).to have_button('About application questions')
    expect(page).not_to have_css('#application-questions-instructions-help.show')
    expect(page).not_to have_content('Department shows for graduate class levels')

    click_button 'About application questions'
    expect(page).to have_css('#application-questions-instructions-help.show')
    expect(page).to have_content('Department shows for graduate class levels')
    expect(page).to have_link('', href: edit_editable_content_path(instructions))

    click_button 'About application questions'
    expect(page).not_to have_css('#application-questions-instructions-help.show')
    expect(page).not_to have_content('Department shows for graduate class levels')
  end

  it 'does not show an edit link to non-Axis Mundi collection administrators' do
    admin_user = create(:user)
    admin_role = create(:role, kind: 'Collection Administrator')
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in admin_user

    visit container_application_questions_path(container)

    click_button 'About application questions'
    expect(page).to have_content('Department shows for graduate class levels')
    expect(page).to have_no_link('', href: edit_editable_content_path(instructions))
  end
end
