# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkContestInstancesController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let!(:source_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }

  before do
    sign_in user
    ApplicationQuestionRequirement.create!(
      application_question: pen_name_question,
      requireable: source_instance,
      status: 'required',
      position: 2
    )
  end

  describe 'POST #create' do
    let(:open_date) { 1.month.from_now.strftime('%Y-%m-%dT00:00') }
    let(:close_date) { 2.months.from_now.strftime('%Y-%m-%dT00:00') }

    it 'copies application question requirements from the most recent instance' do
      expect {
        post :create, params: {
          container_id: container.id,
          contest_description_ids: { source_instance.contest_description_id.to_s => '1' },
          bulk_contest_instance_form: {
            date_open: open_date,
            date_closed: close_date
          }
        }
      }.to change(ContestInstance, :count).by(1)

      new_instance = contest_description.contest_instances.order(:created_at).last
      copied = new_instance.application_question_requirements.find_by!(
        application_question: pen_name_question
      )
      expect(copied.status).to eq('required')
      expect(copied.position).to eq(2)
    end

    it 'assigns a fresh access_token instead of copying the source token' do
      post :create, params: {
        container_id: container.id,
        contest_description_ids: { source_instance.contest_description_id.to_s => '1' },
        bulk_contest_instance_form: {
          date_open: open_date,
          date_closed: close_date
        }
      }

      new_instance = contest_description.contest_instances.order(:created_at).last
      expect(new_instance.access_token).to be_present
      expect(new_instance.access_token).not_to eq(source_instance.access_token)
    end

    it 'rejects closed dates that precede open dates' do
      expect {
        post :create, params: {
          container_id: container.id,
          contest_description_ids: { source_instance.contest_description_id.to_s => '1' },
          bulk_contest_instance_form: {
            date_open: close_date,
            date_closed: open_date
          }
        }
      }.not_to change(ContestInstance, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to eq('Date closed must be after date contest opens')
    end
  end
end
