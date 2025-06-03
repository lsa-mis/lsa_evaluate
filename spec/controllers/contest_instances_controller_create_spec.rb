require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }
  let(:contest_description) { create(:contest_description, container: container) }

  before do
    sign_in user
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        active: true,
        date_open: 1.week.from_now,
        date_closed: 2.weeks.from_now,
        notes: 'Test instance notes',
        maximum_number_entries_per_applicant: 3,
        require_pen_name: false,
        require_campus_employment_info: false,
        require_finaid_info: false,
        created_by: user.email
      }
    end

    let(:invalid_attributes) do
      {
        active: true,
        date_open: 2.weeks.from_now,
        date_closed: 1.week.from_now, # Invalid: close date before open date
        notes: 'Test instance notes'
      }
    end

    context 'with valid parameters' do
      it 'creates a new contest instance' do
        expect {
          post :create, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance: valid_attributes
          }
        }.to change(ContestInstance, :count).by(1)
      end

      it 'redirects to the contest instance page with success notice' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes
        }

        created_instance = ContestInstance.last
        expect(response).to redirect_to(
          container_contest_description_contest_instance_path(container, contest_description, created_instance)
        )
        expect(flash[:notice]).to be_present
      end

      it 'creates active contest instance when active is true' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(active: true)
        }

        created_instance = ContestInstance.last
        expect(created_instance.active).to be true
      end

      it 'creates inactive contest instance when active is false' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(active: false)
        }

        created_instance = ContestInstance.last
        expect(created_instance.active).to be false
      end

      it 'sets the created_by field to current user email' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes
        }

        created_instance = ContestInstance.last
        expect(created_instance.created_by).to eq(user.email)
      end

      it 'associates contest instance with correct contest description' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes
        }

        created_instance = ContestInstance.last
        expect(created_instance.contest_description).to eq(contest_description)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new contest instance' do
        expect {
          post :create, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance: invalid_attributes
          }
        }.not_to change(ContestInstance, :count)
      end

      it 'renders the new template with errors' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: invalid_attributes
        }

        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end

      it 'assigns the contest instance with errors' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: invalid_attributes
        }

        expect(assigns(:contest_instance)).to be_a(ContestInstance)
        expect(assigns(:contest_instance).errors).to be_present
      end
    end

    context 'activation workflow integration' do
      it 'processes activation parameter correctly when coming from JavaScript workflow' do
        # Simulate the JavaScript workflow setting active to true after confirmation
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(active: true) # JS would set this to true
        }

        created_instance = ContestInstance.last
        expect(created_instance.active).to be true
        expect(response).to be_redirect
      end

      it 'respects user choice to keep instance inactive' do
        # Simulate user choosing to keep instance inactive in JavaScript workflow
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(active: false) # JS would leave this as false
        }

        created_instance = ContestInstance.last
        expect(created_instance.active).to be false
        expect(response).to be_redirect
      end
    end

    context 'with categories and class levels' do
      let!(:category1) { create(:category, kind: 'Fiction') }
      let!(:category2) { create(:category, kind: 'Poetry') }
      let!(:class_level1) { create(:class_level, name: 'Undergraduate') }
      let!(:class_level2) { create(:class_level, name: 'Graduate') }

      it 'associates selected categories with contest instance' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(
            category_ids: [category1.id, category2.id]
          )
        }

        created_instance = ContestInstance.last
        expect(created_instance.categories).to include(category1, category2)
      end

      it 'associates selected class levels with contest instance' do
        post :create, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance: valid_attributes.merge(
            class_level_ids: [class_level1.id, class_level2.id]
          )
        }

        created_instance = ContestInstance.last
        expect(created_instance.class_levels).to include(class_level1, class_level2)
      end
    end
  end

  describe 'PUT #update' do
    let!(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: false) }

    let(:update_attributes) do
      {
        active: true,
        notes: 'Updated notes'
      }
    end

    context 'with valid parameters' do
      it 'updates the contest instance' do
        put :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          contest_instance: update_attributes
        }

        contest_instance.reload
        expect(contest_instance.active).to be true
        expect(contest_instance.notes).to eq('Updated notes')
      end

      it 'redirects to the contest instance page' do
        put :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          contest_instance: update_attributes
        }

        expect(response).to redirect_to(
          container_contest_description_contest_instance_path(container, contest_description, contest_instance)
        )
      end
    end

    context 'with invalid parameters' do
      it 'renders the edit template with errors' do
        put :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          contest_instance: { date_closed: 1.day.ago } # Invalid: past date
        }

        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
      end
    end
  end
end
