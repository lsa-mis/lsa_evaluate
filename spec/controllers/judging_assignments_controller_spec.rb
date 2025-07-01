require 'rails_helper'

RSpec.describe JudgingAssignmentsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:admin) { create(:user) }
  let!(:judge_role) { create(:role, kind: 'Judge') }

  before do
    container_admin_role = create(:role, kind: 'Container Administrator')
    create(:assignment, user: admin, container: container, role: container_admin_role)
    allow(controller).to receive(:authorize).and_return(true)
    sign_in admin
  end

  describe '#create_judge' do
    let(:valid_params) do
      {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        email: 'judge@example.com',
        first_name: 'John',
        last_name: 'Doe'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user and assigns judge role' do
        expect {
          post :create_judge, params: valid_params
        }.to change(User, :count).by(1)

        new_user = User.last
        expect(new_user.email).to eq('judge+example.com@umich.edu')
        expect(new_user.roles).to include(judge_role)
      end

      it 'creates container assignment and judging assignment' do
        expect {
          post :create_judge, params: valid_params
        }.to change(Assignment, :count).by(1)
          .and change(JudgingAssignment, :count).by(1)
      end

      it 'handles existing umich.edu email addresses correctly' do
        params = valid_params.merge(email: 'existing@umich.edu')
        post :create_judge, params: params
        expect(User.last.email).to eq('existing@umich.edu')
      end
    end

    context 'with existing user' do
      let!(:existing_user) { create(:user, email: 'judge+example.com@umich.edu') }

      it 'does not create new user but adds judge role' do
        expect {
          post :create_judge, params: valid_params
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.roles).to include(judge_role)
      end

      it 'creates assignments if they do not exist' do
        expect {
          post :create_judge, params: valid_params
        }.to change(Assignment, :count).by(1)
          .and change(JudgingAssignment, :count).by(1)
      end

      it 'does not duplicate existing assignments' do
        existing_user.roles << judge_role
        create(:assignment, user: existing_user, container: container, role: judge_role)
        create(:judging_assignment, user: existing_user, contest_instance: contest_instance)

        expect {
          post :create_judge, params: valid_params
        }.not_to change(Assignment, :count)

        expect {
          post :create_judge, params: valid_params
        }.not_to change(JudgingAssignment, :count)
      end
    end

    context 'with invalid parameters' do
      it 'requires email' do
        post :create_judge, params: valid_params.merge(email: '')
        expect(flash[:alert]).to include('Email, first name, and last name are required')
      end

      it 'requires valid email format' do
        post :create_judge, params: valid_params.merge(email: 'invalid-email')
        expect(flash[:alert]).to include('Please enter a valid email address')
      end

      it 'handles user creation failure' do
        allow_any_instance_of(User).to receive(:save).and_return(false)
        post :create_judge, params: valid_params
        expect(flash[:alert]).to be_present
      end
    end

    context 'with authorization' do
      it 'requires manage_judges? permission' do
        allow(controller).to receive(:authorize).and_call_original
        sign_in create(:user)
        post :create_judge, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#judge_lookup' do
    let!(:available_judge) { create(:user, first_name: 'Alice', last_name: 'Smith', email: 'alice@example.com') }
    let!(:other_judge) { create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob@example.com') }
    let!(:non_judge) { create(:user, first_name: 'Carol', last_name: 'Brown', email: 'carol@example.com') }

    before do
      available_judge.roles << judge_role
      other_judge.roles << judge_role
      # Assign other_judge to this contest_instance (should be excluded)
      create(:judging_assignment, user: other_judge, contest_instance: contest_instance)
    end

    it 'returns only available judges not already assigned' do
      get :judge_lookup, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        q: ''
      }, format: :json
      ids = JSON.parse(response.body).map { |u| u['id'] }
      expect(ids).to include(available_judge.id)
      expect(ids).not_to include(other_judge.id)
      expect(ids).not_to include(non_judge.id)
    end

    it 'filters judges by query' do
      get :judge_lookup, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        q: 'Alice'
      }, format: :json
      results = JSON.parse(response.body)
      expect(results.length).to eq(1)
      expect(results.first['name']).to include('Alice')
    end

    it 'returns JSON with id and name' do
      get :judge_lookup, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        q: 'Alice'
      }, format: :json
      result = JSON.parse(response.body).first
      expect(result.keys).to include('id', 'name')
    end
  end
end
