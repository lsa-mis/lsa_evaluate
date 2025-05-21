require 'rails_helper'

RSpec.describe EntriesController, type: :controller do
  describe "GET #modal_details" do
    let(:profile) { create(:profile) }
    let(:contest_instance) { create(:contest_instance) }
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

    context "when user is entry owner" do
      before do
        sign_in profile.user
        get :modal_details, params: { id: entry.id }
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "renders the details partial" do
        expect(response).to render_template('entries/modal_details')
      end
    end

    context "when user is not authorized" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
        get :modal_details, params: { id: entry.id }
      end

      it "redirects with unauthorized message" do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end
  end
end
