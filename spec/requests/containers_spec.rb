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

  describe "GET /containers/:id" do
    let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) }
    let(:container) { create(:container) }

    context "as an axis_mundi user" do
      before { sign_in axis_mundi_user }

      it "renders section help as accessible accordion dropdowns" do
        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="entries-summary-help"')
        expect(response.body).to include('id="contests-in-collection-help"')
        expect(response.body).to include('data-bs-toggle="collapse"')
        expect(response.body).to include('aria-controls="entries-summary-help"')
        expect(response.body).to include('aria-controls="contests-in-collection-help"')
        expect(response.body).not_to include('title="Summary of active entries across all active contests in this collection"')
        expect(response.body).not_to include('title="Summary of contests within this collection"')
      end

      it "renders collection actions and stacked metadata with accessible entries summary" do
        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Application Questions')
        expect(response.body).to include('Generate Reports')
        expect(response.body).to include('Edit Collection Settings')
        expect(response.body).not_to include('Edit Collection</')
        expect(response.body).to include('<h2')
        expect(response.body).to include('Entries Summary')
        expect(response.body).to include('Total Entries in all Active Instances of Active Contests:')
        expect(response.body).to include('No active entries found.')
        expect(response.body).not_to include('col-md-4')
      end
    end
  end
end
