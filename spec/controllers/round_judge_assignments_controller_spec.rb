# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RoundJudgeAssignmentsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let!(:judging_round) do
    create(:judging_round,
           contest_instance: contest_instance,
           round_number: 1,
           start_date: contest_instance.date_closed + 1.day,
           end_date: contest_instance.date_closed + 10.days)
  end
  let(:admin) { create(:user) }
  let(:judge) { create(:user, :with_judge_role) }

  before do
    container_admin_role = create(:role, kind: 'Container Administrator')
    create(:assignment, user: admin, container: container, role: container_admin_role)
    allow(controller).to receive(:authorize).and_return(true)
    sign_in admin
  end

  describe 'POST #create' do
    let(:base_params) do
      {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        judging_round_id: judging_round.id,
        round_judge_assignment: { user_id: judge.id }
      }
    end

    it 'assigns a pool judge to the round without duplicating the pool assignment' do
      create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      pool_count_before = JudgingAssignment.count

      expect {
        post :create, params: base_params
      }.to change(RoundJudgeAssignment, :count).by(1)

      expect(JudgingAssignment.count).to eq(pool_count_before)
      expect(response).to redirect_to(
        container_contest_description_contest_instance_judging_round_round_judge_assignments_path(
          container, contest_description, contest_instance, judging_round
        )
      )
      expect(judging_round.round_judge_assignments.exists?(user: judge)).to be true
    end

    it 'creates a judging pool assignment when the user is not already in the pool' do
      expect {
        post :create, params: base_params
      }.to change(JudgingAssignment, :count).by(1)
        .and change(RoundJudgeAssignment, :count).by(1)

      expect(contest_instance.judging_assignments.exists?(user: judge)).to be true
      expect(judging_round.round_judge_assignments.exists?(user: judge)).to be true
    end
  end

  describe 'DELETE #destroy' do
    it 'removes the judge from the round without removing the pool assignment' do
      create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      assignment = create(:round_judge_assignment, user: judge, judging_round: judging_round)
      pool_count_before = JudgingAssignment.count

      expect {
        delete :destroy, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          judging_round_id: judging_round.id,
          id: assignment.id
        }
      }.to change(RoundJudgeAssignment, :count).by(-1)

      expect(JudgingAssignment.count).to eq(pool_count_before)
      expect(contest_instance.judging_assignments.exists?(user: judge)).to be true
    end
  end
end
