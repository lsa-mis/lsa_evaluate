# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationQuestionsController, type: :controller do
  let(:container) { create(:container) }
  let(:admin_user) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:unauthorized_user) { create(:user) }

  before do
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in admin_user
  end

  describe 'authorization' do
    it 'denies access to users without a container role' do
      sign_in unauthorized_user

      get :index, params: { container_id: container.id }

      expect(flash[:alert]).to eq('!!! Not authorized !!!')
    end
  end

  describe 'GET #index' do
    render_views

    it 'does not display internal keys on the list' do
      get :index, params: { container_id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('<th>System</th>')
      expect(response.body).not_to include('key: pen_name')
      expect(response.body).to include('Pen name')
      expect(response.body).to include('Short answer (one line)')
      expect(response.body).to include('btn-primary mb-3')
    end
  end

  describe 'GET #new' do
    render_views

    it 'does not display the internal key field' do
      get :new, params: { container_id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Internal key')
      expect(response.body).not_to include('application_question[key]')
    end

    it 'lists answer types in plain language' do
      get :new, params: { container_id: container.id }

      expect(response.body).to include('Short answer (one line)')
      expect(response.body).to include('Paragraph')
      expect(response.body).to include('Yes / no')
      expect(response.body).to include('Dropdown (choose one)')
      expect(response.body).to include('Dropdown with Other')
      expect(response.body).not_to include('>string</option>')
      expect(response.body).not_to include('>select_with_other</option>')
    end
  end

  describe 'GET #edit' do
    render_views

    it 'does not display key fields on a system question and shows the answer type label' do
      question = container.application_questions.find_by!(system_key: 'degree')

      get :edit, params: { container_id: container.id, id: question.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Internal key')
      expect(response.body).not_to include('application_question[key]')
      expect(response.body).to include('Answer type')
      expect(response.body).to include('Short answer (one line)')
    end
  end

  describe 'POST #create' do
    it 'parses newline-separated select choices into an options array' do
      expect {
        post :create, params: {
          container_id: container.id,
          application_question: {
            label: 'Preferred genre',
            field_type: 'select',
            position: 250,
            active: true,
            options: { choices: "Poetry\nFiction\n Drama " }
          }
        }
      }.to change(ApplicationQuestion, :count).by(1)

      question = ApplicationQuestion.order(:id).last
      expect(question.key).to eq('preferred_genre')
      expect(question.options['choices']).to eq(%w[Poetry Fiction Drama])
      expect(response).to redirect_to(container_application_questions_path(container))
    end

    it 'ignores a submitted key and generates one from the label' do
      post :create, params: {
        container_id: container.id,
        application_question: {
          key: 'injected_key',
          label: 'Workshop title',
          field_type: 'string',
          position: 250,
          active: true
        }
      }

      question = ApplicationQuestion.order(:id).last
      expect(question.key).to eq('workshop_title')
      expect(response).to redirect_to(container_application_questions_path(container))
    end

    it 're-renders new when the question is invalid' do
      expect {
        post :create, params: {
          container_id: container.id,
          application_question: {
            label: '',
            field_type: 'string',
            position: 250,
            active: true
          }
        }
      }.not_to change(ApplicationQuestion, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
    end
  end

  describe 'PATCH #update' do
    let(:custom_question) do
      create(:application_question, container: container, key: 'workshop_title', label: 'Workshop title', position: 210)
    end
    let(:system_question) { container.application_questions.find_by!(system_key: 'degree') }

    it 'ignores field_type changes on update' do
      patch :update, params: {
        container_id: container.id,
        id: custom_question.id,
        application_question: {
          label: 'Updated workshop title',
          field_type: 'text'
        }
      }

      expect(response).to redirect_to(container_application_questions_path(container))
      expect(custom_question.reload.label).to eq('Updated workshop title')
      expect(custom_question.field_type).to eq('string')
    end

    it 'does not allow changing the key of a system question' do
      patch :update, params: {
        container_id: container.id,
        id: system_question.id,
        application_question: {
          label: system_question.label,
          key: 'renamed_degree'
        }
      }

      expect(response).to redirect_to(container_application_questions_path(container))
      expect(system_question.reload.key).to eq('degree')
    end
  end

  describe 'DELETE #destroy' do
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:question) do
      create(:application_question, container: container, key: 'optional_prompt', label: 'Optional prompt', position: 220)
    end

    it 'deletes a custom question with no answers' do
      question_id = question.id

      expect {
        delete :destroy, params: { container_id: container.id, id: question_id }
      }.to change(ApplicationQuestion, :count).by(-1)

      expect(response).to redirect_to(container_application_questions_path(container))
      expect(flash[:notice]).to be_present
    end

    it 'refuses to delete a question that already has answers' do
      entry = create(:entry, contest_instance: contest_instance)
      EntryAnswer.create!(entry: entry, application_question: question, value: 'Answered')

      expect {
        delete :destroy, params: { container_id: container.id, id: question.id }
      }.not_to change(ApplicationQuestion, :count)

      expect(response).to redirect_to(container_application_questions_path(container))
      expect(flash[:alert]).to match(/entry answers/i)
      expect(ApplicationQuestion.exists?(question.id)).to be(true)
    end
  end

  describe 'PATCH #update_requirements' do
    let(:question) { container.application_questions.find_by!(system_key: 'pen_name') }

    it 'creates container requirements and clears them when set to inherit' do
      patch :update_requirements, params: {
        container_id: container.id,
        requirements: {
          question.id.to_s => { status: 'required', position: '1' }
        }
      }

      requirement = ApplicationQuestionRequirement.find_by!(
        application_question: question,
        requireable: container
      )
      expect(requirement.status).to eq('required')
      expect(response).to redirect_to(container_application_questions_path(container))

      patch :update_requirements, params: {
        container_id: container.id,
        requirements: {
          question.id.to_s => { status: 'inherit' }
        }
      }

      expect(
        ApplicationQuestionRequirement.where(application_question: question, requireable: container)
      ).to be_empty
    end

    it 'ignores requirements for questions outside the container' do
      other_container = create(:container)
      other_question = other_container.application_questions.find_by!(system_key: 'pen_name')

      expect {
        patch :update_requirements, params: {
          container_id: container.id,
          requirements: {
            other_question.id.to_s => { status: 'required' }
          }
        }
      }.not_to change(ApplicationQuestionRequirement, :count)

      expect(response).to redirect_to(container_application_questions_path(container))
    end
  end
end
