# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkJudgingWindowsController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let!(:judging_round) do
    create(:judging_round,
           contest_instance: contest_instance,
           round_number: 1,
           start_date: contest_instance.date_closed + 1.day,
           end_date: contest_instance.date_closed + 10.days)
  end

  before { sign_in user }

  describe 'POST #create' do
    it 'updates the selected judging round end date' do
      new_end_date = (judging_round.end_date + 2.days).strftime('%Y-%m-%dT%H:%M')

      post :create, params: {
        container_id: container.id,
        judging_round_ids: { judging_round.id.to_s => judging_round.id.to_s },
        bulk_judging_window_form: {
          end_date: new_end_date,
          cascade_following_rounds: '1',
          cascade_mode: 'minimum_bump'
        }
      }

      expect(response).to redirect_to(container_path(container))
      expect(judging_round.reload.end_date).to eq(Time.zone.parse(new_end_date))
    end

    it 'renders new when no rounds are selected' do
      post :create, params: {
        container_id: container.id,
        bulk_judging_window_form: {
          end_date: 1.week.from_now.strftime('%Y-%m-%dT%H:%M')
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to include('select at least one')
    end
  end

  describe 'POST #preview' do
    it 'returns cascade preview data as json' do
      post :preview, params: {
        container_id: container.id,
        judging_round_ids: [judging_round.id],
        end_date: (judging_round.end_date + 5.days).strftime('%Y-%m-%dT%H:%M'),
        cascade_mode: 'minimum_bump'
      }, format: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['plans']).to be_an(Array)
    end
  end
end
