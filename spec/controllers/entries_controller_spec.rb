require 'rails_helper'

RSpec.describe EntriesController, type: :controller do
  describe 'POST #create' do
    let(:class_level) { create(:class_level) }
    let(:profile) { create(:profile, class_level: class_level) }
    let(:user) { profile.user }
    let(:container) { create(:container) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) do
      create(:contest_instance, contest_description: contest_description).tap do |ci|
        ci.class_levels = [class_level]
        ci.save!
      end
    end
    let(:category) { contest_instance.categories.first }
    let(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }
    let(:pdf) do
      fixture_file_upload(
        Rails.root.join('spec/support/files/sample_test.pdf'),
        'application/pdf'
      )
    end

    before do
      ApplicationQuestionRequirement.create!(
        application_question: pen_name_question,
        requireable: contest_instance,
        status: 'required'
      )
      sign_in user
    end

    def create_params(answers: { pen_name_question.id => 'A. Poet' }, class_level_id: class_level.id)
      {
        entry: {
          title: 'New Submission',
          contest_instance_id: contest_instance.id,
          category_id: category.id,
          confirmed_class_level_id: class_level_id,
          entry_file: pdf
        },
        entry_answers: answers
      }
    end

    it 'creates the entry and persists required application answers' do
      expect {
        post :create, params: create_params
      }.to change(Entry, :count).by(1)
       .and change(EntryAnswer, :count).by(1)

      entry = Entry.order(:id).last
      expect(response).to redirect_to(applicant_dashboard_path)
      expect(entry.title).to eq('New Submission')
      expect(entry.entry_answers.find_by!(application_question: pen_name_question).value).to eq('A. Poet')
      expect(profile.reload.class_level_id).to eq(class_level.id)
    end

    it 'does not create an entry when a required answer is missing' do
      expect {
        post :create, params: create_params(answers: {})
      }.not_to change(Entry, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(EntryAnswer.count).to eq(0)
    end

    it 'does not create an entry when class level confirmation is missing' do
      expect {
        post :create, params: create_params(class_level_id: nil)
      }.not_to change(Entry, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:entry).errors[:base]).to include('Class level must be confirmed')
    end
  end

  describe "GET #modal_details" do
    let(:profile) { create(:profile) }
    let(:contest_instance) { create(:contest_instance) }
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

    context "when user is entry owner" do
      before do
        sign_in profile.user
        get :modal_details, params: { id: entry.id }
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "renders the details partial" do
        expect(response).to render_template('entries/modal_details')
      end
    end

    context "when user is a Container Administrator for the entry's container" do
      render_views

      let(:container) { contest_instance.contest_description.container }
      let(:admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let(:custom_question) do
        create(:application_question, container: container, label: 'Favorite form', key: 'favorite_form', position: 200)
      end

      before do
        ApplicationQuestionRequirement.create!(
          application_question: custom_question,
          requireable: contest_instance,
          status: 'required'
        )
        EntryAnswer.create!(entry: entry, application_question: custom_question, value: 'Sonnet')
        create(:assignment, user: admin_user, container: container, role: admin_role)
        sign_in admin_user
        get :modal_details, params: { id: entry.id }
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "renders the details partial" do
        expect(response).to render_template('entries/modal_details')
      end

      it "includes the applicant's application answers" do
        expect(response.body).to include('Application answers')
        expect(response.body).to include('Favorite form')
        expect(response.body).to include('Sonnet')
      end
    end

    context "when user is a judge assigned to the contest instance" do
      render_views

      let(:judge_user) { create(:user, :with_judge_role) }
      let(:container) { contest_instance.contest_description.container }
      let(:custom_question) do
        create(:application_question, container: container, label: 'Favorite form', key: 'favorite_form', position: 200)
      end

      before do
        ApplicationQuestionRequirement.create!(
          application_question: custom_question,
          requireable: contest_instance,
          status: 'required'
        )
        EntryAnswer.create!(entry: entry, application_question: custom_question, value: 'Sonnet')
        create(:judging_assignment, user: judge_user, contest_instance: contest_instance)
        sign_in judge_user
        get :modal_details, params: { id: entry.id }
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "does not include application answers" do
        expect(response.body).not_to include('Application answers')
        expect(response.body).not_to include('Sonnet')
      end
    end

    context "when user is a Collection Administrator for a different container" do
      let(:other_container) { create(:container) }
      let(:other_admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: other_admin_user, container: other_container, role: admin_role)
        sign_in other_admin_user
        get :modal_details, params: { id: entry.id }
      end

      it "redirects with unauthorized message" do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user is not authorized" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
        get :modal_details, params: { id: entry.id }
      end

      it "redirects with unauthorized message" do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end
  end

  describe "PATCH #toggle_disqualified" do
    let(:container) { create(:container) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:profile) { create(:profile) }
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance, disqualified: false) }

    context "when user is a Container Administrator for the container" do
      let(:admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: admin_user, container: container, role: admin_role)
        sign_in admin_user
      end

      it "toggles the disqualification status from false to true" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "toggles the disqualification status from true to false" do
        entry.update(disqualified: true)
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(true).to(false)
      end

      it "redirects to the referer" do
        request.env['HTTP_REFERER'] = '/some/path'
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to('/some/path')
      end

      it "redirects to root path when no referer" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is a Collection Manager for the container" do
      let(:manager_user) { create(:user) }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      before do
        create(:assignment, user: manager_user, container: container, role: manager_role)
        sign_in manager_user
      end

      it "toggles the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is Axis Mundi" do
      let(:axis_mundi_user) { create(:user, :axis_mundi) }

      before do
        sign_in axis_mundi_user
      end

      it "toggles the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.to change { entry.reload.disqualified }.from(false).to(true)
      end

      it "sets a success notice message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(flash[:notice]).to eq('Entry disqualification status has been updated.')
      end
    end

    context "when user is a Container Administrator for a different container" do
      let(:other_container) { create(:container) }
      let(:other_admin_user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: other_admin_user, container: other_container, role: admin_role)
        sign_in other_admin_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user is the entry owner" do
      before do
        sign_in profile.user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user is a judge assigned to the contest instance" do
      let(:judge_user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: judge_user, contest_instance: contest_instance)
        sign_in judge_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end

    context "when user has no special role" do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it "does not toggle the disqualification status" do
        expect {
          patch :toggle_disqualified, params: { id: entry.id }
        }.not_to change { entry.reload.disqualified }
      end

      it "redirects with unauthorized message" do
        patch :toggle_disqualified, params: { id: entry.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("!!! Not authorized !!!")
      end
    end
  end
end
