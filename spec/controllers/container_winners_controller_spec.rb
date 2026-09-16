# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContainerWinnersController, type: :controller do
  let(:container) { create(:container) }
  let(:admin_user) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Poetry') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance, award_status: 'winner', placement: 1) }

  before do
    create(:assignment, user: admin_user, container: container, role: admin_role)
    create(:entry_award, entry: entry, amount: 1000, shortcode: 'SC-1')
    sign_in admin_user
  end

  describe 'GET #show' do
    render_views

    it 'lists awarded entries' do
      get :show, params: { id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(entry.profile.display_name)
      expect(response.body).to include('Poetry')
      expect(response.body).to include('1st')
    end
  end

  describe 'GET #export_roster' do
    it 'downloads a mail-merge CSV' do
      get :export_roster, params: { id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/csv')
      expect(response.body).to include('Award Status')
      expect(response.body).to include('Winner')
      expect(response.body).to include('SC-1')
    end
  end

  describe 'GET #export_disbursement' do
    it 'downloads one row per prize' do
      get :export_disbursement, params: { id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Prize Name')
      expect(response.body).to include('SC-1')
    end
  end
end
