# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
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

    it 'lists catalog categories' do
      create(:category, container: container, kind: 'Research Paper')

      get :index, params: { container_id: container.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Research Paper')
      expect(response.body).to include('Add category')
    end
  end

  describe 'POST #create' do
    it 'creates a collection category' do
      expect {
        post :create, params: {
          container_id: container.id,
          category: {
            kind: 'Equations',
            description: 'Equation-focused submissions'
          }
        }
      }.to change(Category, :count).by(1)

      category = Category.last
      expect(category.kind).to eq('Equations')
      expect(category.container).to eq(container)
      expect(response).to redirect_to(container_categories_path(container))
    end
  end

  describe 'DELETE #destroy' do
    it 'prevents deleting a category that is in use' do
      category = create(:category, container: container, kind: 'Fiction')
      contest_description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: contest_description)
      contest_instance.categories = [ category ]

      expect {
        delete :destroy, params: { container_id: container.id, id: category.id }
      }.not_to change(Category, :count)

      expect(response).to redirect_to(container_categories_path(container))
      expect(flash[:alert]).to be_present
    end
  end
end
