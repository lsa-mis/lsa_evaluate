# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

  before { sign_in user }

  describe 'GET #setup_questions' do
    it 'renders the questions setup step' do
      get :setup_questions, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id
      }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:setup_questions)
    end

    context 'when the user is unauthorized' do
      let(:regular_user) { create(:user) }

      before do
        sign_out user
        sign_in regular_user
      end

      it 'does not allow access' do
        get :setup_questions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end

  describe 'PATCH #update_setup_questions' do
    let(:question) { container.application_questions.find_by!(system_key: 'pen_name') }

    it 'saves question overrides and continues to the review process step' do
      patch :update_setup_questions, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        requirements: {
          question.id.to_s => { status: 'required' }
        }
      }

      requirement = ApplicationQuestionRequirement.find_by!(
        application_question: question,
        requireable: contest_instance
      )
      expect(requirement.status).to eq('required')
      expect(response).to redirect_to(
        setup_review_process_container_contest_description_contest_instance_path(
          container, contest_description, contest_instance
        )
      )
    end

    it 'does not write instance-level rows when statuses are inherit' do
      expect {
        patch :update_setup_questions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          requirements: {
            question.id.to_s => { status: 'inherit' }
          }
        }
      }.not_to change(ApplicationQuestionRequirement, :count)

      expect(response).to redirect_to(
        setup_review_process_container_contest_description_contest_instance_path(
          container, contest_description, contest_instance
        )
      )
    end
  end

  describe 'GET #setup_review_process' do
    it 'renders the review process setup step' do
      get :setup_review_process, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id
      }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:setup_review_process)
      expect(assigns(:judging_round)).to be_a_new(JudgingRound)
    end

    context 'when the user is unauthorized' do
      let(:regular_user) { create(:user) }

      before do
        sign_out user
        sign_in regular_user
      end

      it 'does not allow access' do
        get :setup_review_process, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end
end
