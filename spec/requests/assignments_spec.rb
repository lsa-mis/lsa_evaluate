# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection assignments', type: :request do
  let(:container) { create(:container) }
  let(:admin_role) { create(:role, :collection_admin) }
  let(:axis_mundi) { create(:user, :axis_mundi) }

  before { sign_in axis_mundi }

  describe 'POST /containers/:container_id/assignments' do
    it 'creates an assignment and redirects back to collection settings' do
      assignee = create(:user, uid: 'newstaff')

      expect {
        post container_assignments_path(container), params: {
          assignment: { uid: assignee.uid, role_id: admin_role.id }
        }
      }.to change(Assignment, :count).by(1)

      expect(response).to redirect_to(edit_container_path(container))
      expect(flash[:notice]).to eq('Assignment was successfully created.')
      expect(Assignment.last).to have_attributes(user: assignee, role: admin_role, container: container)
    end

    it 'does not create an assignment when the UID does not exist' do
      expect {
        post container_assignments_path(container),
             params: { assignment: { uid: 'missing-uid', role_id: admin_role.id } },
             as: :turbo_stream
      }.not_to change(Assignment, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end

    it 'denies students who cannot manage the collection' do
      sign_in create(:user, :student)
      assignee = create(:user, uid: 'targetstaff')

      expect {
        post container_assignments_path(container), params: {
          assignment: { uid: assignee.uid, role_id: admin_role.id }
        }
      }.not_to change(Assignment, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('!!! Not authorized !!!')
    end
  end

  describe 'DELETE /containers/:container_id/assignments/:id' do
    it 'removes a non-final administrator and redirects back to collection settings' do
      keep_admin = create(:assignment, container: container, role: admin_role)
      removable = create(:assignment, container: container, role: admin_role)

      expect {
        delete container_assignment_path(container, removable)
      }.to change(Assignment, :count).by(-1)

      expect(response).to redirect_to(edit_container_path(container))
      expect(flash[:notice]).to eq('Assignment was successfully removed.')
      expect(Assignment.exists?(keep_admin.id)).to be(true)
    end

    it 'keeps the last administrator and surfaces the failure on HTML requests' do
      assignment = create(:assignment, container: container, role: admin_role)

      expect {
        delete container_assignment_path(container, assignment)
      }.not_to change(Assignment, :count)

      expect(response).to redirect_to(edit_container_path(container))
      expect(flash[:alert]).to include('Cannot delete the last Container Administrator.')
    end
  end
end
