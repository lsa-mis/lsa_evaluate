# spec/requests/entries_spec.rb
require 'rails_helper'

RSpec.describe "Containers", type: :request do
  describe "GET /containers" do
    context "as an axis_mundi user" do
      let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) } # Ensure you have a trait for axis_mundi

      before do
        sign_in axis_mundi_user
      end

      it "allows access to the index" do
        get containers_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a normal authenticated user" do
      let(:normal_user) { create(:user) }

      before do
        sign_in normal_user
      end

      it "denies access to the index" do
        get containers_path
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "as a guest (unauthenticated user)" do
      it "redirects to the sign-in page" do
        get containers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /containers/:id" do
    let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) }
    let(:container) { create(:container) }

    context "as an axis_mundi user" do
      before { sign_in axis_mundi_user }

      it "renders section help as accessible accordion dropdowns" do
        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="entries-summary-help"')
        expect(response.body).to include('id="contests-in-collection-help"')
        expect(response.body).to include('data-bs-toggle="collapse"')
        expect(response.body).to include('aria-controls="entries-summary-help"')
        expect(response.body).to include('aria-controls="contests-in-collection-help"')
        expect(response.body).not_to include('title="Summary of active entries across all active contests in this collection"')
        expect(response.body).not_to include('title="Summary of contests within this collection"')
      end

      it "renders collection instructions as a collapsed accordion when editable content exists" do
        create(:editable_content, page: 'container', section: 'information').tap do |record|
          record.update!(content: 'The collection is the container of all the contests you want to run.')
        end

        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Collection instructions')
        expect(response.body).to include('id="container-information-help"')
        expect(response.body).to include('aria-controls="container-information-help"')
        expect(response.body).to include('The collection is the container of all the contests you want to run.')
        expect(response.body).to include('accordion-button collapsed')
        expect(response.body).to include('class="accordion-collapse collapse"')
        expect(response.body).not_to include('class="accordion-collapse collapse show"')
      end

      it "renders collection actions and stacked metadata with accessible entries summary" do
        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Application Questions')
        expect(response.body).to include('Generate Reports')
        expect(response.body).to include(reports_container_path(container))
        expect(response.body).not_to include('Generate - Download Report')
        expect(response.body).not_to include('id="reports"')
        expect(response.body).to include('Edit Collection Settings')
        expect(response.body).not_to include('Edit Collection</')
        expect(response.body).to include('<h2')
        expect(response.body).to include('Entries Summary')
        expect(response.body).to include('Total Entries in all Active Instances of Active Contests:')
        expect(response.body).to include('No active entries found.')
        expect(response.body).not_to include('col-md-4')
        expect(response.body).to include('Administrative users')
        expect(response.body).to include('None assigned')
        expect(response.body).not_to include('User Permissions')
        expect(response.body).not_to include('Add New Permission')
      end

      it "renders create contest choice modal actions" do
        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-bs-target="#create-contest-choice-modal"')
        expect(response.body).to include('Create one contest')
        expect(response.body).to include(new_container_contest_description_path(container))
        expect(response.body).not_to include('Bulk Create Contest Instances')
        expect(response.body).to include('Bulk create becomes available after this collection has at least one contest.')
      end

      it "summarizes assigned collection staff on the collection page" do
        admin_user = create(:user, display_name: 'Ada Admin', uid: 'adaadmin')
        manager_user = create(:user, display_name: 'Moe Manager', uid: 'moemanager')
        create(:assignment, user: admin_user, container: container, role: create(:role, :collection_admin))
        create(:assignment, user: manager_user, container: container, role: create(:role, :collection_manager))

        get container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Administrative users')
        expect(response.body).to include('Ada Admin (adaadmin)')
        expect(response.body).to include('Collection Administrator')
        expect(response.body).to include('Moe Manager (moemanager)')
        expect(response.body).to include('Collection Manager')
        expect(response.body).not_to include('None assigned')
      end
    end
  end

  describe "GET /containers/:id/edit" do
    let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) }
    let(:container) { create(:container) }

    context "as an axis_mundi user" do
      before { sign_in axis_mundi_user }

      it "renders user permissions management and collapsed instruction accordions" do
        create(:editable_content, page: 'container', section: 'permissions').tap do |record|
          record.update!(content: 'The permissions listed are for giving users access to manage this collection.')
        end
        create(:editable_content, page: 'container', section: 'form_instructions').tap do |record|
          record.update!(content: 'Instructions for editing collection settings.')
        end

        get edit_container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('User Permissions')
        expect(response.body).to include('Add New Permission')
        expect(response.body).to include('Add User')
        expect(response.body).to include('Permission instructions')
        expect(response.body).to include('id="container-permissions-help"')
        expect(response.body).to include('Collection settings instructions')
        expect(response.body).to include('id="container-form-instructions-help"')
        expect(response.body).to include('The permissions listed are for giving users access to manage this collection.')
        expect(response.body).to include('Instructions for editing collection settings.')
      end
    end
  end

  describe "GET /containers/:id/reports" do
    let(:axis_mundi_user) { create(:user, :with_axis_mundi_role) }
    let(:container) { create(:container) }

    context "as an axis_mundi user" do
      before { sign_in axis_mundi_user }

      it "renders the reports page with the active applicants report" do
        contest_description = create(:contest_description, :active, container: container, name: 'First contest in the new collection')

        get reports_container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Reports')
        expect(response.body).to include('Active Applicants Report')
        expect(response.body).to include('Generate - Download Report')
        expect(response.body).to include(contest_description.name)
        expect(response.body).to include('Return to Manage Collection')
        expect(response.body).to include(container_path(container))
      end

      it "shows an empty state when there are no active contest descriptions" do
        get reports_container_path(container)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('No active contest descriptions are available for this report.')
        expect(response.body).not_to include('Generate - Download Report')
      end
    end

    context "as a guest (unauthenticated user)" do
      it "redirects to the sign-in page" do
        get reports_container_path(container)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
