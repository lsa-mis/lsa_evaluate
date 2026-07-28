# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInvitationsController, type: :controller do
  let(:admin) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:container) { create(:container, :private) }
  let(:description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, :invite_list, contest_description: description) }

  before do
    create(:assignment, user: admin, container: container, role: admin_role)
    sign_in admin
  end

  describe 'POST #create' do
    it 'adds invitees from a bulk email list' do
      expect {
        post :create, params: {
          container_id: container.id,
          contest_description_id: description.id,
          contest_instance_id: contest_instance.id,
          emails: "one@umich.edu\ntwo@umich.edu, three@umich.edu"
        }
      }.to change(ContestInvitation, :count).by(3)

      expect(response).to redirect_to(
        container_contest_description_contest_instance_path(container, description, contest_instance)
      )
    end
  end

  describe 'DELETE #destroy' do
    let!(:invitation) { create(:contest_invitation, contest_instance: contest_instance) }

    it 'removes an invitee' do
      expect {
        delete :destroy, params: {
          container_id: container.id,
          contest_description_id: description.id,
          contest_instance_id: contest_instance.id,
          id: invitation.id
        }
      }.to change(ContestInvitation, :count).by(-1)
    end
  end
end
