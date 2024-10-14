# spec/controllers/applicant_dashboard_controller_spec.rb
require 'rails_helper'

RSpec.describe ApplicantDashboardController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    context 'when user has no profile' do
      it 'redirects to new profile path with alert' do
        get :index
        expect(response).to redirect_to(new_profile_path)
        expect(flash[:alert]).to eq('Please create your profile first.')
      end
    end
  end
end
