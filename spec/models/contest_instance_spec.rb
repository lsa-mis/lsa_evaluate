require 'rails_helper'

RSpec.describe ContestInstance, type: :model do
  describe 'judge assignment methods' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judge) { create(:user, :with_judge_role) }
    let(:regular_user) { create(:user) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }

    describe '#judge_assigned?' do
      it 'returns false for non-judge users' do
        expect(contest_instance.judge_assigned?(regular_user)).to be false
      end

      it 'returns false for unassigned judges' do
        expect(contest_instance.judge_assigned?(judge)).to be false
      end

      it 'returns true for assigned judges' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        expect(contest_instance.judge_assigned?(judge)).to be true
      end

      it 'returns false for inactive assignments' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: false)
        expect(contest_instance.judge_assigned?(judge)).to be false
      end
    end

    describe '#judge_assigned_to_round?' do
      let!(:judging_assignment) do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      end

      it 'returns false when judge is not assigned to round' do
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns true when judge is assigned to round' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be true
      end

      it 'returns false when round assignment is inactive' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: false)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns false when contest assignment is inactive' do
        judging_assignment.update(active: false)
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end
    end
  end
end 