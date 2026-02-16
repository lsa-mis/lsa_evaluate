require 'rails_helper'

RSpec.describe JudgeDashboardController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) do
    create(:contest_instance,
      contest_description: contest_description,
      date_open: 5.days.ago,
      date_closed: 3.days.ago
    )
  end

  let(:judge) { create(:user, :with_judge_role) }

  let!(:round_1) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 1,
      active: true,
      start_date: 2.days.ago,
      end_date: 2.days.from_now
    )
  end

  let!(:round_2) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 2,
      active: false,
      start_date: 3.days.from_now,
      end_date: 5.days.from_now
    )
  end

  before do
    travel_to Time.zone.local(2024, 2, 1, 12, 0, 0)
    sign_in judge
  end

  describe 'GET #index' do
    context 'when judge is assigned to contest and round 1' do
      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: true)
        get :index
      end

      it 'assigns @judging_assignments' do
        expect(assigns(:judging_assignments)).to include(
          have_attributes(contest_instance_id: contest_instance.id)
        )
      end

      it 'assigns @assigned_rounds with only round 1' do
        expect(assigns(:assigned_rounds)).to contain_exactly(round_1)
      end

      it 'returns successful response' do
        expect(response).to be_successful
      end
    end

    context 'when judge is assigned and index renders entries with attachments' do
      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: true)
        create_list(:entry, 3, contest_instance: contest_instance, deleted: false)
      end

      it 'eager loads entry_file attachments to avoid N+1 queries' do
        attachment_queries = 0
        counter = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
          attachment_queries += 1 if payload[:sql] =~ /active_storage_attachments/
        end

        get :index

        ActiveSupport::Notifications.unsubscribe(counter)

        # With eager loading we should have at most 2 queries (attachments + blobs), not one per entry
        expect(attachment_queries).to be <= 2
      end
    end

    context 'when judge is assigned to contest but no rounds' do
      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        get :index
      end

      it 'assigns empty @assigned_rounds' do
        expect(assigns(:assigned_rounds)).to be_empty
      end

      it 'returns successful response' do
        expect(response).to be_successful
      end
    end

    context 'when judge has inactive round assignment' do
      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: false)
        get :index
      end

      it 'does not include inactive rounds in @assigned_rounds' do
        expect(assigns(:assigned_rounds)).to be_empty
      end
    end

    context 'when judge is assigned to multiple rounds' do
      before do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)

        # Create active assignment for round 1 but then deactivate the round
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: true)
        round_1.update!(active: false)
        round_1.reload

        # Activate round 2 and create active assignment
        round_2.update!(active: true)
        round_2.reload
        create(:round_judge_assignment, user: judge, judging_round: round_2, active: true)

        # Force reload of contest_instance to refresh associations
        contest_instance.reload

        get :index
      end

      it 'includes only rounds that are active and have active assignments' do
        assigned_rounds = assigns(:assigned_rounds)

        # Verify both the round and its assignment are active
        expect(assigned_rounds).to contain_exactly(round_2)
        expect(assigned_rounds.first.active).to be true
        expect(assigned_rounds.first.round_judge_assignments.where(user: judge).first.active).to be true
      end

      it 'orders rounds by round number' do
        expect(assigns(:assigned_rounds).to_a).to eq([ round_2 ])
      end
    end

    context 'when judge has no contest assignments' do
      before do
        get :index
      end

    context 'when contest_instance is inactive' do
      it 'does not display the contest in the judge dashboard' do
        contest_instance = create(:contest_instance, active: false, contest_description: contest_description)
        judging_round = create(:judging_round, contest_instance: contest_instance, active: true, completed: false)
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)

        get :index

        expect(assigns(:judging_assignments)).to be_empty
        expect(response.body).not_to include(contest_instance.contest_description.name)
      end
    end

    context 'when contest_instance is active but the assigned judging round is completed' do
      it 'does not display the contest in the judge dashboard' do
        # contest_instance = create(:contest_instance, active: true, contest_description: contest_description)
        # judging_round = create(:judging_round, contest_instance: contest_instance, active: true, completed: true)
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        create(:round_judge_assignment, user: judge, judging_round: round_1)
        round_1.update!(completed: true)

        get :index

        expect(assigns(:judging_assignments)).to be_empty
        expect(response.body).not_to include(contest_instance.contest_description.name)
      end
    end

      it 'assigns empty @judging_assignments' do
        expect(assigns(:judging_assignments)).to be_empty
      end

      it 'assigns empty @assigned_rounds' do
        expect(assigns(:assigned_rounds)).to be_empty
      end

      it 'returns successful response' do
        expect(response).to be_successful
      end
    end
  end
end
