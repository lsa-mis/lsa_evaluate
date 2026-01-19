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

  describe "PATCH #toggle_disqualified" do
    let(:container) { create(:container) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:profile) { create(:profile) }
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance, disqualified: false) }

    context "when user is a Container Administrator for the container" do
      let(:admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: admin_user, container: container, role: admin_role)
        sign_in admin_user
      end

      it "toggles the disqualification status from false to true" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "toggles the disqualification status from true to false" do
        entry.update(disqualified: true)
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(true).to(false)
      end

      it "redirects to the referer" do
        request.env['HTTP_REFERER'] = '/some/path'
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to('/some/path')
      end

      it "redirects to root path when no referer" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is a Collection Manager for the container" do
      let(:manager_user) { create(:user) }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      before do
        create(:assignment, user: manager_user, container: container, role: manager_role)
        sign_in manager_user
      end

      it "toggles the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is Axis Mundi" do
      let(:axis_mundi_user) { create(:user, :axis_mundi) }

      before do
        sign_in axis_mundi_user
      end

      it "toggles the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is a Container Administrator for a different container" do
      let(:other_container) { create(:container) }
      let(:other_admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: other_admin_user, container: other_container, role: admin_role)
        sign_in other_admin_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user is the entry owner" do
      before do
        sign_in profile.user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user is a judge assigned to the contest instance" do
      let(:judge_user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: judge_user, contest_instance: contest_instance)
        sign_in judge_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user has no special role" do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end
  end
end
