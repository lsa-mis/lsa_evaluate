require 'rails_helper'

RSpec.describe JudgingAssignment, type: :model do
  describe 'associations' do
    # it { should belong_to(:user) }
    # it { should belong_to(:contest_instance) }
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a contest_instance' do
      association = described_class.reflect_on_association(:contest_instance)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:judge_role) { create(:role, kind: 'Judge') }
    let(:judge) { create(:user) }
    let(:contest_instance) { create(:contest_instance) }

    before do
      create(:user_role, user: judge, role: judge_role)
    end

    it 'is valid with valid attributes' do
      judging_assignment = build(:judging_assignment, user: judge, contest_instance: contest_instance)
      expect(judging_assignment).to be_valid
    end

    it 'validates uniqueness of user_id scoped to contest_instance_id' do
      create(:judging_assignment, user: judge, contest_instance: contest_instance)
      duplicate_assignment = build(:judging_assignment, user: judge, contest_instance: contest_instance)
      expect(duplicate_assignment).not_to be_valid
      expect(duplicate_assignment.errors[:user_id]).to include('has already been taken')
    end

    describe 'user_must_be_judge validation' do
      let(:non_judge) { create(:user) }

      it 'is invalid if user is not a judge' do
        judging_assignment = build(:judging_assignment, user: non_judge, contest_instance: contest_instance)
        expect(judging_assignment).not_to be_valid
        expect(judging_assignment.errors[:user]).to include('must have judge role')
      end

      it 'is valid if user is a judge' do
        judging_assignment = build(:judging_assignment, user: judge, contest_instance: contest_instance)
        expect(judging_assignment).to be_valid
      end

      it 'is invalid if user is nil' do
        judging_assignment = build(:judging_assignment, user: nil, contest_instance: contest_instance)
        expect(judging_assignment).not_to be_valid
      end
    end
  end

  describe 'default values' do
    it 'sets active to true by default' do
      judging_assignment = described_class.new
      expect(judging_assignment.active).to be true
    end
  end

  describe 'scopes' do
    let!(:active_assignment) { create(:judging_assignment) }
    let!(:inactive_assignment) { create(:judging_assignment, :inactive) }

    it 'has an active scope' do
      expect(described_class).to respond_to(:active)
      expect(described_class.active).to include(active_assignment)
      expect(described_class.active).not_to include(inactive_assignment)
    end
  end

  describe 'database constraints' do
    it 'has a unique index on user_id and contest_instance_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:judging_assignments, 
        [:user_id, :contest_instance_id], unique: true)).to be true
    end

    it 'has foreign key constraints' do
      expect(described_class.connection.foreign_keys('judging_assignments').map(&:column))
        .to include('user_id', 'contest_instance_id')
    end
  end
end 