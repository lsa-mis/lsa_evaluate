# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInvitationsController, type: :controller do
  let(:admin) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:container) { create(:container, :private) }
  let(:description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, :invite_list, contest_description: description) }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    create(:assignment, user: admin, container: container, role: admin_role)
    sign_in admin
    allow(ContestInviteMailer).to receive(:invite_to_submit).and_return(mail_delivery)
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

    it 'queues an invite email for each newly created invitee' do
      expect(ContestInviteMailer).to receive(:invite_to_submit).exactly(2).times.and_return(mail_delivery)
      expect(mail_delivery).to receive(:deliver_later).twice

      post :create, params: {
        container_id: container.id,
        contest_description_id: description.id,
        contest_instance_id: contest_instance.id,
        emails: "new1@umich.edu\nnew2@umich.edu"
      }

      expect(flash[:notice]).to match(/queued/i)
    end

    it 'does not email duplicate invitees that were skipped' do
      create(:contest_invitation, contest_instance: contest_instance, email: 'existing@umich.edu')

      expect(ContestInviteMailer).to receive(:invite_to_submit).once.and_return(mail_delivery)
      expect(mail_delivery).to receive(:deliver_later).once

      post :create, params: {
        container_id: container.id,
        contest_description_id: description.id,
        contest_instance_id: contest_instance.id,
        emails: "existing@umich.edu\nbrandnew@umich.edu"
      }

      expect(contest_instance.contest_invitations.count).to eq(2)
    end

    context 'when access mode is capability_url' do
      let(:contest_instance) { create(:contest_instance, :capability_url, contest_description: description) }

      it 'rejects creating invitees until invite_list mode is saved' do
        expect {
          post :create, params: {
            container_id: container.id,
            contest_description_id: description.id,
            contest_instance_id: contest_instance.id,
            emails: 'someone@umich.edu'
          }
        }.not_to change(ContestInvitation, :count)

        expect(response).to redirect_to(
          container_contest_description_contest_instance_path(container, description, contest_instance)
        )
        expect(flash[:alert]).to match(/invite list only/i)
      end
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

    context 'when access mode is capability_url' do
      let(:contest_instance) { create(:contest_instance, :capability_url, contest_description: description) }
      let!(:invitation) do
        # Bypass mode guard to seed a leftover invitee from a prior mode.
        ContestInvitation.create!(contest_instance: contest_instance, email: 'leftover@umich.edu')
      end

      it 'rejects removing invitees' do
        expect {
          delete :destroy, params: {
            container_id: container.id,
            contest_description_id: description.id,
            contest_instance_id: contest_instance.id,
            id: invitation.id
          }
        }.not_to change(ContestInvitation, :count)

        expect(flash[:alert]).to match(/invite list only/i)
      end
    end
  end

  describe 'POST #email_all' do
    let!(:invitation_one) do
      create(:contest_invitation, contest_instance: contest_instance, email: 'one@umich.edu')
    end
    let!(:invitation_two) do
      create(:contest_invitation, contest_instance: contest_instance, email: 'two@umich.edu')
    end

    it 'queues invite emails for every invitee on the list' do
      expect(ContestInviteMailer).to receive(:invite_to_submit).exactly(2).times.and_return(mail_delivery)
      expect(mail_delivery).to receive(:deliver_later).twice

      post :email_all, params: {
        container_id: container.id,
        contest_description_id: description.id,
        contest_instance_id: contest_instance.id
      }

      expect(response).to redirect_to(
        container_contest_description_contest_instance_path(container, description, contest_instance)
      )
      expect(flash[:notice]).to match(/queued invite emails for 2/i)
    end

    it 'alerts when there are no invitees' do
      contest_instance.contest_invitations.destroy_all

      expect(ContestInviteMailer).not_to receive(:invite_to_submit)

      post :email_all, params: {
        container_id: container.id,
        contest_description_id: description.id,
        contest_instance_id: contest_instance.id
      }

      expect(flash[:alert]).to match(/no invitees/i)
    end

    context 'when access mode is capability_url' do
      let(:contest_instance) { create(:contest_instance, :capability_url, contest_description: description) }
      let!(:invitation_one) do
        ContestInvitation.create!(contest_instance: contest_instance, email: 'one@umich.edu')
      end
      let!(:invitation_two) do
        ContestInvitation.create!(contest_instance: contest_instance, email: 'two@umich.edu')
      end

      it 'rejects emailing invitees' do
        expect(ContestInviteMailer).not_to receive(:invite_to_submit)

        post :email_all, params: {
          container_id: container.id,
          contest_description_id: description.id,
          contest_instance_id: contest_instance.id
        }

        expect(flash[:alert]).to match(/invite list only/i)
      end
    end

    context 'when the user is not authorized' do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it 'redirects unauthorized users' do
        post :email_all, params: {
          container_id: container.id,
          contest_description_id: description.id,
          contest_instance_id: contest_instance.id
        }

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
