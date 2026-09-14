# == Schema Information
#
# Table name: round_judge_assignments
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  instructions_sent_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  judging_round_id     :bigint           not null
#  user_id              :bigint           not null
#
require 'rails_helper'

RSpec.describe RoundJudgeAssignment, type: :model do
  let(:contest_description) { create(:contest_description, :active) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }
  let(:judging_round) do
    create(
      :judging_round,
      contest_instance: contest_instance,
      round_number: 1,
      start_date: contest_instance.date_closed + 1.day,
      end_date: contest_instance.date_closed + 10.days
    )
  end
  let(:judge) { create(:user, :with_judge_role) }

  before do
    create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
  end

  describe 'associations' do
    it 'belongs to a user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to a judging_round' do
      expect(described_class.reflect_on_association(:judging_round).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid when the user is a contest judge' do
      assignment = build(:round_judge_assignment, user: judge, judging_round: judging_round)
      expect(assignment).to be_valid
    end

    it 'validates uniqueness of user_id scoped to judging_round_id' do
      create(:round_judge_assignment, user: judge, judging_round: judging_round)
      duplicate = build(:round_judge_assignment, user: judge, judging_round: judging_round)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end

    it 'is invalid when the user lacks the judge role' do
      non_judge = create(:user)
      assignment = build(:round_judge_assignment, user: non_judge, judging_round: judging_round)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:user]).to include('must have judge role')
    end

    it 'is invalid when the user is not in the contest judging pool' do
      other_judge = create(:user, :with_judge_role)
      assignment = build(:round_judge_assignment, user: other_judge, judging_round: judging_round)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:user]).to include('must be assigned to the contest first')
    end
  end

  describe 'scopes' do
    it 'includes only active assignments in .active' do
      active = create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
      other_judge = create(:user, :with_judge_role)
      create(:judging_assignment, user: other_judge, contest_instance: contest_instance, active: true)
      inactive = create(:round_judge_assignment, :inactive, user: other_judge, judging_round: judging_round)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(inactive)
    end
  end
end
