# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contest instance entries', type: :request do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:admin_user) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:profile) { create(:profile) }
  let(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }
  let(:custom_question) do
    create(:application_question, container: container, label: 'Writing sample prompt', key: 'writing_sample_prompt', position: 200)
  end
  let!(:entry) do
    create(:entry, contest_instance: contest_instance, profile: profile, title: 'River Stones').tap do |created_entry|
      EntryAnswer.create!(entry: created_entry, application_question: pen_name_question, value: 'A. Poet')
      EntryAnswer.create!(entry: created_entry, application_question: custom_question, value: 'Memory of water')
    end
  end

  before do
    ApplicationQuestionRequirement.create!(
      application_question: pen_name_question,
      requireable: contest_instance,
      status: 'required'
    )
    ApplicationQuestionRequirement.create!(
      application_question: custom_question,
      requireable: contest_instance,
      status: 'required'
    )
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in admin_user
  end

  it 'lists all application question answers on the entries tab' do
    get container_contest_description_contest_instance_path(container, contest_description, contest_instance)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pen name')
    expect(response.body).to include('A. Poet')
    expect(response.body).to include('Writing sample prompt')
    expect(response.body).to include('Memory of water')
    expect(response.body).to include('View application answers')
    expect(response.body).to include(modal_details_entry_path(entry))
  end
end
