require 'rails_helper'

RSpec.describe EntryRankingsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  
  describe 'POST #create' do
    let(:valid_params) do
      {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        judging_round_id: judging_round.id,
        entry_ranking: {
          entry_id: entry.id,
          judging_round_id: judging_round.id,
          rank: 1
        }
      }
    end

    context 'when user is not logged in' do
      it 'redirects to login' do
        post :create, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in as regular user' do
      let(:user) { create(:user) }
      before { sign_in user }

      it 'redirects with access denied' do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied')
      end
    end

    context 'when logged in as unassigned judge' do
      let(:judge) { create(:user, :with_judge_role) }
      before { sign_in judge }

      it 'redirects with not assigned message' do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You are not assigned to this contest')
      end
    end

    context 'when logged in as assigned judge' do
      let(:judge) { create(:user, :with_judge_role) }
      before do
        sign_in judge
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
      end

      it 'creates the ranking' do
        expect {
          post :create, params: valid_params
        }.to change(EntryRanking, :count).by(1)
        
        expect(response).to redirect_to(judge_dashboard_path)
        expect(flash[:notice]).to eq('Ranking saved successfully.')
      end
    end
  end
end 