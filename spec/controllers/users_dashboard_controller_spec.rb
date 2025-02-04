# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersDashboardController, type: :controller do
  let!(:axis_mundi_user) { create(:user, :axis_mundi) }
  let!(:admin_user) { create(:user, :with_collection_admin_role) }
  let!(:regular_user) { create(:user) }

  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in as axis mundi user' do
      before do
        sign_in axis_mundi_user
      end

      it 'returns successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns paginated users' do
        get :index
        expect(assigns(:users)).to be_a(ActiveRecord::Relation)
        expect(assigns(:pagy)).to be_a(Pagy)
      end

      it 'sorts users by specified column' do
        get :index, params: { sort: 'current_sign_in_at', direction: 'desc' }
        expect(assigns(:users).to_sql).to include('ORDER BY `users`.`current_sign_in_at` DESC')
      end
    end

    context 'when logged in as admin user' do
      before { sign_in admin_user }

      it 'redirects to root with unauthorized message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end

    context 'when logged in as regular user' do
      before { sign_in regular_user }

      it 'redirects to root with unauthorized message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end

  describe 'GET #show' do
    let(:target_user) { create(:user) }

    context 'when user is not logged in' do
      it 'redirects to login page' do
        get :show, params: { id: target_user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in as axis mundi user' do
      before { sign_in axis_mundi_user }

      it 'returns successful response' do
        get :show, params: { id: target_user.id }
        expect(response).to be_successful
      end

      it 'assigns the requested user' do
        get :show, params: { id: target_user.id }
        expect(assigns(:user)).to eq(target_user)
      end
    end

    context 'when logged in as admin user' do
      before { sign_in admin_user }

      it 'redirects to root with unauthorized message' do
        get :show, params: { id: target_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end

    context 'when logged in as regular user' do
      before { sign_in regular_user }

      it 'redirects to root with unauthorized message' do
        get :show, params: { id: target_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end
end
