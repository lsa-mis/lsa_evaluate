# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#  role_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_assignments_on_container_id              (container_id)
#  index_assignments_on_role_id                   (role_id)
#  index_assignments_on_role_user_container       (role_id,user_id,container_id) UNIQUE
#  index_assignments_on_user_id                   (user_id)
#  index_assignments_on_user_id_and_container_id  (user_id,container_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Assignment, type: :model do
  let(:user) { create(:user) }
  let(:container) { create(:container) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:manager_role) { create(:role, kind: 'Collection Manager') }
  let(:judge_role) { create(:role, kind: 'Judge') }

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a container' do
      association = described_class.reflect_on_association(:container)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a role' do
      association = described_class.reflect_on_association(:role)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'validations' do
    subject { build(:assignment) }

    it 'requires a user_id' do
      subject.user_id = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:user_id]).to include("can't be blank")
    end

    describe 'role combinations' do
      context 'when assigning administrator role' do
        let!(:admin_assignment) { create(:assignment, user: user, container: container, role: admin_role) }

        it 'prevents adding manager role to an administrator' do
          manager_assignment = build(:assignment, user: user, container: container, role: manager_role)
          expect(manager_assignment).not_to be_valid
          expect(manager_assignment.errors[:base]).to include('User can only be either a Collection Administrator or Collection Manager')
        end

        it 'allows adding judge role to an administrator' do
          judge_assignment = build(:assignment, user: user, container: container, role: judge_role)
          expect(judge_assignment).to be_valid
        end
      end

      context 'when assigning manager role' do
        let!(:manager_assignment) { create(:assignment, user: user, container: container, role: manager_role) }

        it 'prevents adding administrator role to a manager' do
          admin_assignment = build(:assignment, user: user, container: container, role: admin_role)
          expect(admin_assignment).not_to be_valid
          expect(admin_assignment.errors[:base]).to include('User can only be either a Collection Administrator or Collection Manager')
        end

        it 'allows adding judge role to a manager' do
          judge_assignment = build(:assignment, user: user, container: container, role: judge_role)
          expect(judge_assignment).to be_valid
        end
      end

      context 'when assigning judge role' do
        let!(:judge_assignment) { create(:assignment, user: user, container: container, role: judge_role) }

        it 'prevents adding another judge role' do
          second_judge_assignment = build(:assignment, user: user, container: container, role: judge_role)
          expect(second_judge_assignment).not_to be_valid
          expect(second_judge_assignment.errors[:base]).to include('User can only have one Judge role per container')
        end

        it 'allows adding administrator role to a judge' do
          admin_assignment = build(:assignment, user: user, container: container, role: admin_role)
          expect(admin_assignment).to be_valid
        end

        it 'allows adding manager role to a judge' do
          manager_assignment = build(:assignment, user: user, container: container, role: manager_role)
          expect(manager_assignment).to be_valid
        end
      end
    end
  end

  describe 'admin removal protection' do
    let!(:admin_assignment) { create(:assignment, user: user, container: container, role: admin_role) }

    it 'prevents removing the last administrator' do
      expect { admin_assignment.destroy }.not_to change(Assignment, :count)
      expect(admin_assignment.errors[:base]).to include('Cannot delete the last Container Administrator.')
    end

    it 'allows removing an administrator when others exist' do
      create(:assignment, container: container, role: admin_role) # create another admin
      expect { admin_assignment.destroy }.to change(Assignment, :count).by(-1)
    end
  end

  describe 'role combination validations' do
    let(:container) { create(:container) }
    let(:user) { create(:user) }

    context 'with administrator and manager roles' do
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      it 'prevents assigning both administrator and manager roles' do
        create(:assignment, user: user, container: container, role: admin_role)
        new_assignment = build(:assignment, user: user, container: container, role: manager_role)

        expect(new_assignment).not_to be_valid
        expect(new_assignment.errors[:base]).to include('User can only be either a Collection Administrator or Collection Manager')
      end
    end

    context 'with judge role combinations' do
      let(:judge_role) { create(:role, kind: 'Judge') }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      it 'allows judge role alongside administrator role' do
        create(:assignment, user: user, container: container, role: admin_role)
        judge_assignment = build(:assignment, user: user, container: container, role: judge_role)

        expect(judge_assignment).to be_valid
      end

      it 'prevents multiple judge roles for the same container' do
        create(:assignment, user: user, container: container, role: judge_role)
        duplicate_judge = build(:assignment, user: user, container: container, role: judge_role)

        expect(duplicate_judge).not_to be_valid
        expect(duplicate_judge.errors[:base]).to include('User can only have one Judge role per container')
      end
    end
  end
end
