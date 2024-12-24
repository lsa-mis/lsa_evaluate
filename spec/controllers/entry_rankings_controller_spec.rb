require 'rails_helper'

RSpec.describe EntryRankingsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:judge) { create(:user, :with_judge_role) }
  let(:collection_admin) { create(:user, :with_collection_admin_role) }
  let!(:judging_assignment) { create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true) }
  let!(:round_judge_assignment) { create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true) }
  let!(:entry_ranking) { create(:entry_ranking, user: judge, entry: entry, judging_round: judging_round) }

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        entry_id: create(:entry, contest_instance: contest_instance).id,
        judging_round_id: judging_round.id,
        rank: 1,
        internal_comments: 'These are internal comments for the judging committee',
        external_comments: 'These are external comments for the applicant'
      }
    end

    context 'when user is a judge' do
      before do
        sign_in judge
      end

      context 'with valid params' do
        it 'creates a new entry ranking with comments' do
          expect {
            post :create, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              judging_round_id: judging_round.id,
              entry_ranking: valid_attributes
            }
          }.to change(EntryRanking, :count).by(1)

          # Add debugging for failures
          if response.status == 422
            puts "Validation errors: #{JSON.parse(response.body)['errors']}"
          end

          entry_ranking = EntryRanking.last
          expect(entry_ranking.internal_comments).to eq('These are internal comments for the judging committee')
          expect(entry_ranking.external_comments).to eq('These are external comments for the applicant')
          expect(entry_ranking.user).to eq(judge)
          expect(entry_ranking.judging_round).to eq(judging_round)
        end
      end

      context 'when internal comments are required' do
        before do
          judging_round.update(
            require_internal_comments: true,
            min_internal_comment_words: 5
          )
        end

        context 'with insufficient internal comments' do
          let(:invalid_attributes) do
            valid_attributes.merge(internal_comments: 'Too short')
          end

          it 'does not create the entry ranking' do
            expect {
              post :create, params: {
                container_id: container.id,
                contest_description_id: contest_description.id,
                contest_instance_id: contest_instance.id,
                judging_round_id: judging_round.id,
                entry_ranking: invalid_attributes
              }
            }.not_to change(EntryRanking, :count)

            # Add debugging for failures
            if response.status == 422
              puts "Validation errors: #{JSON.parse(response.body)['errors']}"
            end
          end

          it 'returns unprocessable entity status' do
            post :create, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              judging_round_id: judging_round.id,
              entry_ranking: invalid_attributes
            }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end

    context 'when user is not a judge' do
      let(:non_judge) { create(:user) }

      before { sign_in non_judge }

      it 'redirects to root' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          judging_round_id: judging_round.id,
          entry_ranking: valid_attributes
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:entry_ranking) do
      create(:entry_ranking,
        entry: entry,
        judging_round: judging_round,
        user: judge,
        rank: 1,
        internal_comments: 'Original internal comments',
        external_comments: 'Original external comments'
      )
    end

    let(:valid_attributes) do
      {
        rank: 2,
        internal_comments: 'Updated internal comments with sufficient length',
        external_comments: 'Updated external comments with more than enough words to meet requirements'
      }
    end

    context 'when user is the judge who created the ranking' do
      before { sign_in judge }

      context 'with valid params' do
        it 'updates the entry ranking comments' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: entry_ranking.id,
            entry_ranking: valid_attributes
          }
          entry_ranking.reload
          expect(entry_ranking.internal_comments).to eq('Updated internal comments with sufficient length')
          expect(entry_ranking.external_comments).to eq('Updated external comments with more than enough words to meet requirements')
        end
      end
    end
  end

  describe 'PATCH #select_for_next_round' do
    context 'when user is a collection admin' do
      before { sign_in collection_admin }

      it 'allows selection of entry for next round' do
        patch :select_for_next_round, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          judging_round_id: judging_round.id,
          id: entry_ranking.id,
          selected_for_next_round: '1'
        }

        expect(entry_ranking.reload.selected_for_next_round).to be true
        expect(response).to redirect_to(
          container_contest_description_contest_instance_judging_round_path(
            container, contest_description, contest_instance, judging_round
          )
        )
        expect(flash[:notice]).to eq('Entry selection updated successfully.')
      end

      it 'allows deselection of entry for next round' do
        entry_ranking.update(selected_for_next_round: true)

        patch :select_for_next_round, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          judging_round_id: judging_round.id,
          id: entry_ranking.id,
          selected_for_next_round: '0'
        }

        expect(entry_ranking.reload.selected_for_next_round).to be false
        expect(flash[:notice]).to eq('Entry selection updated successfully.')
      end
    end

    context 'when user is not a collection admin' do
      before { sign_in judge }

      it 'denies access to selection' do
        patch :select_for_next_round, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          judging_round_id: judging_round.id,
          id: entry_ranking.id,
          selected_for_next_round: '1'
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Only Collection Administrators can select entries for the next round')
      end
    end
  end
end
