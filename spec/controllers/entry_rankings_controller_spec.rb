require 'rails_helper'

RSpec.describe EntryRankingsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:judge) { create(:user, :with_judge_role) }
  let!(:judging_assignment) { create(:judging_assignment, user: judge, contest_instance: contest_instance) }
  let!(:round_judge_assignment) { create(:round_judge_assignment, user: judge, judging_round: judging_round) }

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        entry_id: entry.id,
        judging_round_id: judging_round.id,
        rank: 1,
        internal_comments: 'These are internal comments for the judging committee',
        external_comments: 'These are external comments for the applicant'
      }
    end

    context 'when user is a judge' do
      before { sign_in judge }

      context 'with valid params' do
        it 'creates a new entry ranking with comments' do
          expect {
            post :create, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              entry_ranking: valid_attributes
            }
          }.to change(EntryRanking, :count).by(1)

          entry_ranking = EntryRanking.last
          expect(entry_ranking.internal_comments).to eq('These are internal comments for the judging committee')
          expect(entry_ranking.external_comments).to eq('These are external comments for the applicant')
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
                entry_ranking: invalid_attributes
              }
            }.not_to change(EntryRanking, :count)
          end

          it 'returns unprocessable entity status' do
            post :create, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              entry_ranking: invalid_attributes
            }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context 'when external comments are required' do
        before do
          judging_round.update(
            require_external_comments: true,
            min_external_comment_words: 10
          )
        end

        context 'with insufficient external comments' do
          let(:invalid_attributes) do
            valid_attributes.merge(external_comments: 'Too short feedback')
          end

          it 'does not create the entry ranking' do
            expect {
              post :create, params: {
                container_id: container.id,
                contest_description_id: contest_description.id,
                contest_instance_id: contest_instance.id,
                entry_ranking: invalid_attributes
              }
            }.not_to change(EntryRanking, :count)
          end

          it 'returns unprocessable entity status' do
            post :create, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
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

      context 'when internal comments are required' do
        before do
          judging_round.update(
            require_internal_comments: true,
            min_internal_comment_words: 5
          )
        end

        context 'with insufficient internal comments' do
          let(:invalid_attributes) do
            valid_attributes.merge(internal_comments: 'Short')
          end

          it 'does not update the entry ranking' do
            patch :update, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              id: entry_ranking.id,
              entry_ranking: invalid_attributes
            }
            entry_ranking.reload
            expect(entry_ranking.internal_comments).to eq('Original internal comments')
          end

          it 'returns unprocessable entity status' do
            patch :update, params: {
              container_id: container.id,
              contest_description_id: contest_description.id,
              contest_instance_id: contest_instance.id,
              id: entry_ranking.id,
              entry_ranking: invalid_attributes
            }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end

    context 'when user is not the judge who created the ranking' do
      let(:other_judge) { create(:user, :with_judge_role) }

      before { sign_in other_judge }

      it 'redirects to root' do
        patch :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: entry_ranking.id,
          entry_ranking: valid_attributes
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
