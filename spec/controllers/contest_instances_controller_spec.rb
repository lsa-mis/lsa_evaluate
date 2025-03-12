require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  # Add existing specs if there are any...

  describe 'POST #send_round_results' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) } # Admin user with full privileges
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

    before do
      sign_in user
    end

    context 'with valid judging round' do
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }
      let(:profile1) { create(:profile) }
      let(:profile2) { create(:profile) }
      let(:entry1) { create(:entry, contest_instance: contest_instance, profile: profile1) }
      let(:entry2) { create(:entry, contest_instance: contest_instance, profile: profile2) }
      let!(:entry_ranking1) { create(:entry_ranking, :with_assigned_judge, entry: entry1, judging_round: judging_round) }
      let!(:entry_ranking2) { create(:entry_ranking, :with_assigned_judge, entry: entry2, judging_round: judging_round) }

      before do
        # Add entries to the judging round
        allow(judging_round).to receive(:entries).and_return([ entry1, entry2 ])
        allow(judging_round.entries).to receive(:uniq).and_return([ entry1, entry2 ])

        # Configure ActiveJob to use inline adapter for testing
        ActiveJob::Base.queue_adapter = :inline
      end

      it 'sends emails for each entry' do
        expect(ResultsMailer).to receive(:entry_evaluation_notification).with(entry1, judging_round).and_call_original
        expect(ResultsMailer).to receive(:entry_evaluation_notification).with(entry2, judging_round).and_call_original

        expect {
          post :send_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      it 'increments the emails_sent_count for the judging round' do
        expect {
          post :send_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id
          }
        }.to change { judging_round.reload.emails_sent_count }.by(1)
      end

      it 'redirects with a success notice' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:notice]).to include("Successfully queued 2 evaluation result emails")
        expect(flash[:notice]).to include("email batch #1")
      end
    end

    context 'with non-existent judging round' do
      it 'redirects with an alert' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: 9999 # Non-existent round
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Judging round not found.')
      end
    end

    context 'with incomplete judging round' do
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: false) }

      it 'redirects with an alert' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Cannot send results for an incomplete judging round.')
      end
    end

    context 'with unauthorized user' do
      let(:regular_user) { create(:user) }
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }

      before do
        sign_out user
        sign_in regular_user
      end

      it 'does not allow access to the action' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end
end
