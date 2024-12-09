require 'rails_helper'

RSpec.describe JudgingAssignmentsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:admin_user) { create(:user) }
  let(:container_role) { create(:role, kind: 'Collection Administrator') }
  let(:judge_role) { create(:role, :judge) }

  let(:valid_params) do
    {
      container_id: container.id,
      contest_description_id: contest_description.id,
      contest_instance_id: contest_instance.id,
      email: 'judge@gmail.com',
      first_name: 'John',
      last_name: 'Doe'
    }
  end

  describe 'POST #create_judge' do
    context 'when user has container role' do
      before do
        create(:assignment, user: admin_user, container: container, role: container_role)
        sign_in admin_user
      end

      context 'with valid params' do
        before do
          # Ensure judge role exists
          judge_role # Reference the let to ensure it's created
        end

        it 'creates a new user with transformed email' do
          expect {
            post :create_judge, params: valid_params
          }.to change(User, :count).by(1)

          new_user = User.last
          expect(new_user.email).to eq('judge+gmail.com@umich.edu')
          expect(new_user.first_name).to eq('John')
          expect(new_user.last_name).to eq('Doe')
        end

        it 'assigns the Judge role to the new user' do
          post :create_judge, params: valid_params
          new_user = User.last
          expect(new_user.roles).to include(judge_role)
        end

        it 'creates a judging assignment' do
          expect {
            post :create_judge, params: valid_params
          }.to change(JudgingAssignment, :count).by(1)

          assignment = JudgingAssignment.last
          expect(assignment.contest_instance).to eq(contest_instance)
          expect(assignment.user.email).to eq('judge+gmail.com@umich.edu')
        end
      end
    end
  end
end
