# spec/requests/entries_spec.rb
require 'rails_helper'

RSpec.describe "Containers", type: :request do
  describe "GET /containers" do
    context "as an axis_mundi user" do
      let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) } # Ensure you have a trait for axis_mundi

      before do
        sign_in axis_mundi_user
      end

      it "allows access to the index" do
        get containers_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a normal authenticated user" do
      let(:normal_user) { create(:user) }

      before do
        sign_in normal_user
      end

      it "denies access to the index" do
        get containers_path
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "as a guest (unauthenticated user)" do
      it "redirects to the sign-in page" do
        get containers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
