# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk activation report', type: :request do
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, name: 'Hopwood') }
  let(:other_container) { create(:container, name: 'Other collection') }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Poetry Award') }
  let(:season_open) { 1.month.from_now.change(usec: 0) }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    create(
      :contest_instance,
      contest_description: contest_description,
      active: true,
      date_open: 2.months.ago,
      date_closed: 1.month.ago
    )
    create(
      :contest_instance,
      contest_description: contest_description,
      active: false,
      date_open: season_open,
      date_closed: season_open + 1.month
    )
    sign_in user
  end

  it 'shows the report only on the collection that was activated' do
    post container_bulk_contest_instance_activations_path(container), params: {
      bulk_contest_instance_activation_form: {
        date_open: season_open.iso8601,
        confirmed: '1'
      }
    }

    expect(response).to redirect_to(container_path(container))
    expect(session[:bulk_activation_report_key]).to be_present

    get container_path(other_container)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('Bulk activation report')
    expect(response.body).not_to include('Poetry Award')
    expect(session[:bulk_activation_report_key]).to be_present

    get container_path(container)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Bulk activation report')
    expect(response.body).to include('Poetry Award')
    expect(session[:bulk_activation_report_key]).to be_blank

    get container_path(container)

    expect(response.body).not_to include('Bulk activation report')
  end
end
