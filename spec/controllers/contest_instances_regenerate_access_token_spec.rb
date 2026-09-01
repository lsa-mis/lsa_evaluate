# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  describe 'POST #regenerate_access_token' do
    let(:admin) { create(:user) }
    let(:admin_role) { create(:role, kind: 'Collection Administrator') }
    let(:container) { create(:container, :private) }
    let(:description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: description) }

    before do
      create(:assignment, user: admin, container: container, role: admin_role)
      sign_in admin
    end

    it 'regenerates the access token' do
      old_token = contest_instance.access_token

      post :regenerate_access_token, params: {
        container_id: container.id,
        contest_description_id: description.id,
        id: contest_instance.id
      }

      expect(contest_instance.reload.access_token).not_to eq(old_token)
      expect(response).to redirect_to(
        container_contest_description_contest_instance_path(container, description, contest_instance)
      )
      expect(flash[:notice]).to match(/regenerated/i)
    end

    context 'when the user is a judge for the contest instance' do
      let(:judge) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance)
        sign_in judge
      end

      it 'does not regenerate the access token' do
        old_token = contest_instance.access_token

        post :regenerate_access_token, params: {
          container_id: container.id,
          contest_description_id: description.id,
          id: contest_instance.id
        }

        expect(contest_instance.reload.access_token).to eq(old_token)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end

    context 'when the user administers a different container' do
      let(:other_admin) { create(:user) }
      let(:other_container) { create(:container) }

      before do
        create(:assignment, user: other_admin, container: other_container, role: admin_role)
        sign_in other_admin
      end

      it 'does not regenerate the access token' do
        old_token = contest_instance.access_token

        post :regenerate_access_token, params: {
          container_id: container.id,
          contest_description_id: description.id,
          id: contest_instance.id
        }

        expect(contest_instance.reload.access_token).to eq(old_token)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end
end
