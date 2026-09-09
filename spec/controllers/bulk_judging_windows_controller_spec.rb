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

    it 'renders new when the bulk form is invalid' do
      original_end_date = judging_round.end_date

      post :create, params: {
        container_id: container.id,
        judging_round_ids: { judging_round.id.to_s => judging_round.id.to_s },
        bulk_judging_window_form: {
          end_date: '',
          cascade_following_rounds: '1',
          cascade_mode: 'minimum_bump'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
      expect(judging_round.reload.end_date).to eq(original_end_date)
    end

    it 'renders new with failure details when the updater rejects a round' do
      allow(BulkJudgingWindowUpdater).to receive(:new).and_return(
        instance_double(
          BulkJudgingWindowUpdater,
          call: BulkJudgingWindowUpdater::Result.new(
            updated: [],
            failed: [ {
              contest_name: contest_description.name,
              round_number: judging_round.round_number,
              errors: [ 'End date must be after start date' ]
            } ],
            cascaded: []
          )
        )
      )

      post :create, params: {
        container_id: container.id,
        judging_round_ids: { judging_round.id.to_s => judging_round.id.to_s },
        bulk_judging_window_form: {
          end_date: (judging_round.end_date + 2.days).strftime('%Y-%m-%dT%H:%M'),
          cascade_following_rounds: '1',
          cascade_mode: 'minimum_bump'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to include(contest_description.name)
      expect(flash.now[:alert]).to include("Round #{judging_round.round_number}")
      expect(flash.now[:alert]).to include('End date must be after start date')
    end
  end

  describe 'authorization' do
    it 'denies users who cannot manage judging for the container' do
      sign_in create(:user, :employee)

      post :create, params: {
        container_id: container.id,
        judging_round_ids: { judging_round.id.to_s => judging_round.id.to_s },
        bulk_judging_window_form: {
          end_date: (judging_round.end_date + 2.days).strftime('%Y-%m-%dT%H:%M')
        }
      }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('!!! Not authorized !!!')
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

  describe 'container scoping' do
    let(:admin_user) { create(:user) }
    let(:admin_role) { create(:role, kind: 'Collection Administrator') }
    let(:other_container) { create(:container, department: department) }
    let(:other_description) { create(:contest_description, :active, container: other_container, name: 'Secret Contest') }
    let(:other_instance) { create(:contest_instance, contest_description: other_description) }
    let!(:other_round) do
      create(:judging_round,
             contest_instance: other_instance,
             round_number: 1,
             start_date: other_instance.date_closed + 1.day,
             end_date: other_instance.date_closed + 10.days)
    end

    before do
      create(:assignment, user: admin_user, container: container, role: admin_role)
      sign_in admin_user
    end

    it 'does not preview judging rounds from another container' do
      post :preview, params: {
        container_id: container.id,
        judging_round_ids: [other_round.id],
        end_date: (other_round.end_date + 5.days).strftime('%Y-%m-%dT%H:%M'),
        cascade_mode: 'minimum_bump'
      }, format: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['plans']).to eq([])
      expect(response.body).not_to include(other_description.name)
    end

    it 'does not update judging rounds from another container' do
      original_end_date = other_round.end_date

      post :create, params: {
        container_id: container.id,
        judging_round_ids: { other_round.id.to_s => other_round.id.to_s },
        bulk_judging_window_form: {
          end_date: (other_round.end_date + 2.days).strftime('%Y-%m-%dT%H:%M'),
          cascade_following_rounds: '1',
          cascade_mode: 'minimum_bump'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(other_round.reload.end_date).to eq(original_end_date)
      expect(flash.now[:alert]).to include('select at least one')
    end

    it 'updates owned rounds and ignores foreign round ids in the same request' do
      original_other_end_date = other_round.end_date
      new_end_date = (judging_round.end_date + 2.days).strftime('%Y-%m-%dT%H:%M')

      post :create, params: {
        container_id: container.id,
        judging_round_ids: {
          judging_round.id.to_s => judging_round.id.to_s,
          other_round.id.to_s => other_round.id.to_s
        },
        bulk_judging_window_form: {
          end_date: new_end_date,
          cascade_following_rounds: '0',
          cascade_mode: 'minimum_bump'
        }
      }

      expect(response).to redirect_to(container_path(container))
      expect(judging_round.reload.end_date).to eq(Time.zone.parse(new_end_date))
      expect(other_round.reload.end_date).to eq(original_other_end_date)
    end
  end
end
