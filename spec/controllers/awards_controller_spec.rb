# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwardsController, type: :controller do
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

    it 'lists catalog awards' do
      create(:award, container: container, name: 'First Place')

      get :index, params: { container_id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('First Place')
      expect(response.body).to include('Add award')
    end
  end

  describe 'POST #create' do
    it 'creates a collection award' do
      expect {
        post :create, params: {
          container_id: container.id,
          award: {
            name: 'Hopwood Major',
            kind: 'add_on',
            default_amount: 500,
            default_shortcode: 'P/G999',
            active: true
          }
        }
      }.to change(Award, :count).by(1)

      award = Award.last
      expect(award.name).to eq('Hopwood Major')
      expect(award).to be_add_on
      expect(award.default_shortcode).to eq('P/G999')
      expect(response).to redirect_to(container_awards_path(container))
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an unassigned award' do
      award = create(:award, container: container)

      expect {
        delete :destroy, params: { container_id: container.id, id: award.id }
      }.to change(Award, :count).by(-1)
    end

    it 'does not delete an assigned award' do
      award = create(:award, container: container)
      contest_description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: contest_description)
      entry = create(:entry, contest_instance: contest_instance)
      create(:entry_award, entry: entry, award: award)

      expect {
        delete :destroy, params: { container_id: container.id, id: award.id }
      }.not_to change(Award, :count)

      expect(flash[:alert]).to be_present
    end
  end
end
