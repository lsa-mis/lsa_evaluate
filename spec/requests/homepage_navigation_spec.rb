# spec/requests/static_pages_spec.rb
require 'rails_helper'

RSpec.describe 'StaticPages', type: :request do
  describe 'GET /home' do
    context 'when user is not signed in' do
      it 'renders the home template' do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:home)
      end

      it 'does not render the choose_interaction partial' do
        get root_path
        expect(response.body).not_to include('data-controller="interaction"')
        expect(response.body).not_to include('data-interaction-target="content"')
      end
    end

    context 'when user is signed in' do
      let!(:user) { create(:user, :student) }

      # before do
      #   mock_login({
      #                email: user.email,
      #                name: user.display_name,
      #                uniqname: user.uniqname
      #              }) # Use Devise's sign_in method to simulate user login
      # end
      before do
        sign_in user
      end

      it 'renders the choose_interaction partial' do
        get root_path
        expect(response.body).to include('data-controller="interaction"')
        expect(response.body).to include('data-interaction-target="content"')
      end
    end
  end
end
