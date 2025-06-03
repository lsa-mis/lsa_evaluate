require 'rails_helper'

RSpec.describe ContestDescriptionsController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, container: container) }

  before do
    sign_in user
  end

  describe 'GET #new' do
    it 'assigns a new contest description' do
      get :new, params: { container_id: container.id }
      expect(assigns(:contest_description)).to be_a_new(ContestDescription)
      expect(assigns(:contest_description).container).to eq(container)
    end

    it 'renders the new template' do
      get :new, params: { container_id: container.id }
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'Test Contest',
        created_by: user.email,
        eligibility_rules: 'Test rules',
        notes: 'Test notes',
        short_name: 'test',
        active: true
      }
    end

    let(:invalid_attributes) do
      {
        name: '', # Required field
        created_by: user.email
      }
    end

    context 'with valid parameters' do
      it 'creates a new contest description' do
        expect {
          post :create, params: {
            container_id: container.id,
            contest_description: valid_attributes
          }
        }.to change(ContestDescription, :count).by(1)
      end

      it 'redirects to the container page with success notice' do
        post :create, params: {
          container_id: container.id,
          contest_description: valid_attributes
        }
        expect(response).to redirect_to(container_path(container))
        expect(flash[:notice]).to be_present
      end

      it 'creates active contest description when active is true' do
        post :create, params: {
          container_id: container.id,
          contest_description: valid_attributes.merge(active: true)
        }
        created_contest = ContestDescription.last
        expect(created_contest.active).to be true
      end

      it 'creates inactive contest description when active is false' do
        post :create, params: {
          container_id: container.id,
          contest_description: valid_attributes.merge(active: false)
        }
        created_contest = ContestDescription.last
        expect(created_contest.active).to be false
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new contest description' do
        expect {
          post :create, params: {
            container_id: container.id,
            contest_description: invalid_attributes
          }
        }.not_to change(ContestDescription, :count)
      end

      it 'renders the new template with errors' do
        post :create, params: {
          container_id: container.id,
          contest_description: invalid_attributes
        }
        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end

      it 'assigns the contest description with errors' do
        post :create, params: {
          container_id: container.id,
          contest_description: invalid_attributes
        }
        expect(assigns(:contest_description)).to be_a(ContestDescription)
        expect(assigns(:contest_description).errors).to be_present
      end
    end

    context 'with Turbo Stream requests' do
      it 'responds with turbo stream for successful creation' do
        post :create, params: {
          container_id: container.id,
          contest_description: valid_attributes
        }, as: :turbo_stream

        expect(response.status).to eq(302) # Redirect
      end

      it 'responds with turbo stream for validation errors' do
        post :create, params: {
          container_id: container.id,
          contest_description: invalid_attributes
        }, as: :turbo_stream

        expect(response.status).to eq(422)
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'PUT #update' do
    let(:update_attributes) do
      {
        name: 'Updated Contest',
        active: false
      }
    end

    context 'with valid parameters' do
      it 'updates the contest description' do
        put :update, params: {
          container_id: container.id,
          id: contest_description.id,
          contest_description: update_attributes
        }
        contest_description.reload
        expect(contest_description.name).to eq('Updated Contest')
      end

      it 'redirects to the container page' do
        put :update, params: {
          container_id: container.id,
          id: contest_description.id,
          contest_description: update_attributes
        }
        expect(response).to redirect_to(container_path(container))
      end
    end

    context 'when trying to deactivate with active instances' do
      let!(:active_instance) { create(:contest_instance, contest_description: contest_description, active: true) }

      it 'prevents deactivation and shows error' do
        put :update, params: {
          container_id: container.id,
          id: contest_description.id,
          contest_description: { active: false }
        }

        expect(response.status).to eq(422)
        expect(flash[:alert]).to include('Cannot deactivate contest description while it has active instances')
        contest_description.reload
        expect(contest_description.active).to be true # Should remain active
      end

      it 'responds with turbo stream for active instance prevention' do
        put :update, params: {
          container_id: container.id,
          id: contest_description.id,
          contest_description: { active: false }
        }, as: :turbo_stream

        expect(response.status).to eq(422)
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end

    context 'with invalid parameters' do
      it 'renders the edit template with errors' do
        put :update, params: {
          container_id: container.id,
          id: contest_description.id,
          contest_description: { name: '' } # Invalid - name is required
        }
        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
      end
    end
  end
end
