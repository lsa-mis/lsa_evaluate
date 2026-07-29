# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInvitesController, type: :controller do
  let(:class_level) { create(:class_level) }
  let(:user) { create(:user) }
  let!(:profile) { create(:profile, user: user, class_level: class_level) }

  before { sign_in user }

  describe 'GET #show' do
    context 'with a private capability_url contest' do
      let(:container) { create(:container, :private) }
      let(:description) { create(:contest_description, :active, container: container) }
      let(:contest_instance) do
        create(:contest_instance, contest_description: description).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it 'redeems the token in session and redirects to new entry' do
        get :show, params: { token: contest_instance.access_token }

        expect(session[:redeemed_contest_instances][contest_instance.id.to_s])
          .to eq(contest_instance.access_token)
        expect(response).to redirect_to(new_entry_path(contest_instance_id: contest_instance.id))
      end
    end

    context 'with a private invite_list contest' do
      let(:container) { create(:container, :private) }
      let(:description) { create(:contest_description, :active, container: container) }
      let(:contest_instance) do
        create(:contest_instance, :invite_list, contest_description: description).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it 'denies access when the user is not invited' do
        get :show, params: { token: contest_instance.access_token }

        expect(response).to redirect_to(applicant_dashboard_path)
        expect(flash[:alert]).to match(/not invited/i)
        expect(session[:redeemed_contest_instances]).to be_blank
      end

      it 'allows access when the user is invited' do
        create(:contest_invitation, contest_instance: contest_instance, email: user.email)
        get :show, params: { token: contest_instance.access_token }

        expect(response).to redirect_to(new_entry_path(contest_instance_id: contest_instance.id))
      end
    end

    context 'with an invalid token' do
      it 'redirects with an alert' do
        get :show, params: { token: 'not-a-real-token' }

        expect(response).to redirect_to(applicant_dashboard_path)
        expect(flash[:alert]).to match(/invalid or expired/i)
      end
    end

    context 'when the user has no profile' do
      let(:user_without_profile) { create(:user) }
      let(:contest_instance) { create(:contest_instance) }

      before { sign_in user_without_profile }

      it 'redirects to profile creation' do
        get :show, params: { token: contest_instance.access_token }

        expect(response).to redirect_to(new_profile_path)
        expect(session[:pending_contest_invite_token]).to eq(contest_instance.access_token)
      end
    end
  end
end
