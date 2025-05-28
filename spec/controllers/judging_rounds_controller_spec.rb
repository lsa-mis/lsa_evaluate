require 'rails_helper'

RSpec.describe JudgingRoundsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:admin) { create(:user) }
  let(:judge) { create(:user, :with_judge_role) }

  before do
    container_admin_role = create(:role, kind: 'Collection Administrator')
    create(:assignment, user: admin, container: container, role: container_admin_role)
  end

  describe 'GET #edit' do
    context 'when user is container administrator' do
      before { sign_in admin }

      it 'assigns the requested judging round' do
        get :edit, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
        expect(assigns(:judging_round)).to eq(judging_round)
      end
    end

    context 'when user is not container administrator' do
      before { sign_in judge }

      it 'redirects to root' do
        get :edit, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:valid_attributes) do
      {
        round_number: 1,
        start_date: contest_instance.date_closed + 1.day,
        end_date: contest_instance.date_closed + 2.days,
        require_internal_comments: true,
        min_internal_comment_words: 5,
        require_external_comments: true,
        min_external_comment_words: 10
      }
    end

    context 'when user is container administrator' do
      before { sign_in admin }

      context 'with valid params' do
        it 'updates the judging round' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: valid_attributes
          }
          judging_round.reload
          expect(judging_round.require_internal_comments).to be true
          expect(judging_round.min_internal_comment_words).to eq(5)
          expect(judging_round.require_external_comments).to be true
          expect(judging_round.min_external_comment_words).to eq(10)
        end

        it 'redirects to judging assignments' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: valid_attributes
          }
          expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
            container, contest_description, contest_instance
          ))
        end
      end

      context 'with invalid params' do
        let(:invalid_attributes) { { start_date: nil } }

        it 'does not update the judging round' do
          original_start_date = judging_round.start_date
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: invalid_attributes
          }
          judging_round.reload
          expect(judging_round.start_date).to eq(original_start_date)
        end

        it 're-renders the edit template' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: invalid_attributes
          }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not container administrator' do
      before { sign_in judge }

      it 'redirects to root' do
        patch :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judging_round: valid_attributes
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
