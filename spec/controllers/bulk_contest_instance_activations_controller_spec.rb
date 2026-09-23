# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkContestInstanceActivationsController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:season_open) { 1.month.from_now.change(usec: 0) }
  let!(:predecessor) do
    create(
      :contest_instance,
      contest_description: contest_description,
      active: true,
      date_open: 2.months.ago,
      date_closed: 1.month.ago
    )
  end
  let!(:newest) do
    create(
      :contest_instance,
      contest_description: contest_description,
      active: false,
      date_open: season_open,
      date_closed: season_open + 1.month
    )
  end

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before { sign_in user }

  describe 'GET #new' do
    it 'renders the activation form for a season' do
      get :new, params: { container_id: container.id, date_open: season_open.iso8601 }

      expect(response).to have_http_status(:ok)
      expect(assigns(:season_instances)).to include(newest)
    end

    it 'denies users without container access' do
      sign_in create(:user)

      get :new, params: { container_id: container.id }

      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'POST #create' do
    it 'activates the season and redirects with a report' do
      post :create, params: {
        container_id: container.id,
        bulk_contest_instance_activation_form: {
          date_open: season_open.iso8601,
          confirmed: '1'
        }
      }

      expect(response).to redirect_to(container_path(container))
      expect(flash[:notice]).to eq('Contest instances were successfully activated.')
      expect(newest.reload).to be_active
      expect(predecessor.reload).not_to be_active

      report_key = session[:bulk_activation_report_key]
      expect(report_key).to be_present
      report = Rails.cache.read(report_key)
      expect(report).to be_present
      activated = report.with_indifferent_access[:activated]
      expect(activated).to be_present
      expect(activated.first['contest_name']).to eq(contest_description.name)
    end

    it 'rejects malformed season dates without raising' do
      post :create, params: {
        container_id: container.id,
        bulk_contest_instance_activation_form: {
          date_open: '2026-99-99',
          confirmed: '1'
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(newest.reload).not_to be_active
    end

    it 'requires confirmation' do
      post :create, params: {
        container_id: container.id,
        bulk_contest_instance_activation_form: {
          date_open: season_open.iso8601,
          confirmed: '0'
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(newest.reload).not_to be_active
    end
  end
end
