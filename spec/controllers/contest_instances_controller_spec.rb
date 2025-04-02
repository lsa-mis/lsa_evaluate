require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  # Add existing specs if there are any...

  describe 'GET #email_preferences' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) } # Admin user with full privileges
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }

    before do
      sign_in user
    end

    it 'renders the email_preferences template' do
      get :email_preferences, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        round_id: judging_round.id
      }

      expect(response).to render_template(:email_preferences)
    end

    it 'assigns the judging round' do
      get :email_preferences, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        round_id: judging_round.id
      }

      expect(assigns(:judging_round)).to eq(judging_round)
    end

    context 'with non-existent judging round' do
      it 'redirects with an alert' do
        get :email_preferences, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: 9999 # Non-existent round
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Judging round not found.')
      end
    end

    context 'with incomplete judging round' do
      let(:incomplete_round) { create(:judging_round, contest_instance: contest_instance, completed: false) }

      it 'redirects with an alert' do
        get :email_preferences, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: incomplete_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Cannot send results for an incomplete judging round.')
      end
    end
  end

  describe 'POST #send_round_results' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) } # Admin user with full privileges
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

    before do
      sign_in user
    end

    context 'with valid judging round' do
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }
      let(:profile1) { create(:profile) }
      let(:profile2) { create(:profile) }
      let(:entry1) { create(:entry, contest_instance: contest_instance, profile: profile1) }
      let(:entry2) { create(:entry, contest_instance: contest_instance, profile: profile2) }
      let!(:entry_ranking1) { create(:entry_ranking, :with_assigned_judge, entry: entry1, judging_round: judging_round) }
      let!(:entry_ranking2) { create(:entry_ranking, :with_assigned_judge, entry: entry2, judging_round: judging_round) }

      before do
        # Add entries to the judging round
        allow(judging_round).to receive(:entries).and_return([ entry1, entry2 ])
        allow(judging_round.entries).to receive(:uniq).and_return([ entry1, entry2 ])

        # Configure ActiveJob to use inline adapter for testing
        ActiveJob::Base.queue_adapter = :inline

        # Mock the mailer to return a proper mail object
        allow(ResultsMailer).to receive(:entry_evaluation_notification).and_wrap_original do |original_method, *args|
          mail = original_method.call(*args)
          allow(mail).to receive(:deliver_now) do
            ActionMailer::Base.deliveries << mail
            true
          end
          allow(mail).to receive(:deliver_later) do
            ActionMailer::Base.deliveries << mail
            true
          end
          mail
        end
      end

      it 'sends emails for each entry' do
        # Verify the mailer was called with the correct arguments
        expect(ResultsMailer).to receive(:entry_evaluation_notification).with(entry1, judging_round)
        expect(ResultsMailer).to receive(:entry_evaluation_notification).with(entry2, judging_round)

        expect {
          post :send_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      it 'increments the emails_sent_count for the judging round' do
        expect {
          post :send_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id
          }
        }.to change { judging_round.reload.emails_sent_count }.by(1)
      end

      it 'redirects with a success notice' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:notice]).to include("Successfully queued 2 evaluation result emails")
        expect(flash[:notice]).to include("email batch #1")
      end

      it 'updates email preferences when provided' do
        # Initially both preferences should be true (default)
        judging_round.update(include_average_ranking: true, include_advancement_status: true)

        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id,
          include_average_ranking: "0",
          include_advancement_status: "0"
        }

        # After the request, both should be false
        judging_round.reload
        expect(judging_round.include_average_ranking).to be false
        expect(judging_round.include_advancement_status).to be false
      end

      it 'preserves email preferences when not provided' do
        # Set initial values
        judging_round.update(include_average_ranking: false, include_advancement_status: false)

        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        # Values should remain unchanged
        judging_round.reload
        expect(judging_round.include_average_ranking).to be false
        expect(judging_round.include_advancement_status).to be false
      end
    end

    context 'with non-existent judging round' do
      it 'redirects with an alert' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: 9999 # Non-existent round
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Judging round not found.')
      end
    end

    context 'with incomplete judging round' do
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: false) }

      it 'redirects with an alert' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Cannot send results for an incomplete judging round.')
      end
    end

    context 'with unauthorized user' do
      let(:regular_user) { create(:user) }
      let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }

      before do
        sign_out user
        sign_in regular_user
      end

      it 'does not allow access to the action' do
        post :send_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end

  describe 'GET #export_entries' do
    let(:department) { create(:department) }
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, container: container) }

    context 'with authorized users' do
      let(:user) { create(:user, :axis_mundi) }

      before do
        sign_in user
      end

      context 'contest instance with entries' do
        let(:contest_instance) do
          create(:contest_instance,
                 contest_description: contest_description,
                 require_pen_name: true,
                 require_campus_employment_info: true)
        end

        let(:profile1) { create(:profile, class_level: create(:class_level, name: 'Freshman')) }
        let(:profile2) { create(:profile, class_level: create(:class_level, name: 'Senior')) }
        let(:profile3) { create(:profile, class_level: create(:class_level, name: 'Graduate')) }

        let!(:entry1) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile1,
                 pen_name: 'Writer One',
                 campus_employee: false,
                 title: 'Entry One')
        end

        let!(:entry2) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile2,
                 pen_name: 'Writer Two',
                 campus_employee: true,
                 title: 'Entry Two')
        end

        let!(:entry3) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile3,
                 pen_name: 'Writer Three',
                 campus_employee: false,
                 disqualified: true,
                 title: 'Entry Three')
        end

        it 'returns a CSV file' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          expect(response).to be_successful
          expect(response.content_type).to include('text/csv')
          expect(response.headers['Content-Disposition']).to include('attachment')
          expect(response.headers['Content-Disposition']).to include('.csv')
        end

        it 'includes all active entries in the CSV' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          csv = CSV.parse(response.body)
          # Skip header rows (contest info and empty row)
          data_rows = csv[3..-1] # Starting from the fourth row (index 3) which has actual entry data

          # Should include all active entries
          expect(data_rows.length).to eq(3)

          # Check for specific entry details
          expect(csv.to_s).to include('Entry One')
          expect(csv.to_s).to include('Entry Two')
          expect(csv.to_s).to include('Entry Three')
          expect(csv.to_s).to include('Writer One')
          expect(csv.to_s).to include('Writer Two')
          expect(csv.to_s).to include('Writer Three')

          # Check for class levels
          expect(csv.to_s).to include('Freshman')
          expect(csv.to_s).to include('Senior')
          expect(csv.to_s).to include('Graduate')

          # Check for disqualified status
          expect(csv.to_s).to include('Yes') # For disqualified entry
          expect(csv.to_s).to include('No')  # For non-disqualified entries
        end

        it 'generates CSV with correct structure and headers' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          csv = CSV.parse(response.body)

          # Row 0: Contest info header
          expect(csv[0][0]).to include(contest_description.name)

          # Row 1: Should be separator row - check it doesn't contain significant content
          expect(csv[1].join.strip).to be_empty

          # Row 2: Column headers (12 columns as per generate_entries_csv method)
          expected_headers = [
            'Title', 'Category',
            'Pen Name', 'First Name', 'Last Name', 'UMID', 'Uniqname',
            'Class Level', 'Campus', 'Entry ID', 'Created At', 'Disqualified'
          ]
          expect(csv[2]).to eq(expected_headers)

          # Check structure of data rows
          entry_row = csv.find { |row| row[0] == 'Entry One' }
          expect(entry_row).not_to be_nil

          # For entry1
          expect(entry_row[0]).to eq('Entry One')                  # Title
          expect(entry_row[2]).to eq('Writer One')                 # Pen Name
          expect(entry_row[3]).to eq(profile1.user.first_name)     # First Name
          expect(entry_row[4]).to eq(profile1.user.last_name)      # Last Name
          expect(entry_row[5]).to eq(profile1.umid)                # UMID
          expect(entry_row[6]).to eq(profile1.user.uniqname)       # Uniqname
          expect(entry_row[7]).to eq('Freshman')                   # Class Level
          expect(entry_row[9]).to eq(entry1.id.to_s)               # Entry ID
          expect(entry_row[11]).to eq('No')                        # Disqualified

          # For disqualified entry
          disqualified_row = csv.find { |row| row[0] == 'Entry Three' }
          expect(disqualified_row).not_to be_nil
          expect(disqualified_row[11]).to eq('Yes')                # Disqualified
        end
      end

      context 'contest instance without entries' do
        let(:empty_contest_instance) { create(:contest_instance, contest_description: contest_description) }

        it 'returns a CSV with only headers' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: empty_contest_instance.id,
            format: :csv
          }

          expect(response).to be_successful
          expect(response.content_type).to include('text/csv')

          csv = CSV.parse(response.body)
          # Should have header rows but no data rows
          expect(csv.length).to be >= 3
          expect(csv[3..-1]).to be_empty if csv.length > 3
        end
      end

      context 'contest instance with entries but no optional fields' do
        let(:basic_contest_instance) do
          create(:contest_instance,
                 contest_description: contest_description,
                 require_pen_name: false,
                 require_campus_employment_info: false)
        end

        let(:profile) { create(:profile) }

        let!(:basic_entry) do
          create(:entry,
                 contest_instance: basic_contest_instance,
                 profile: profile,
                 pen_name: nil,
                 title: 'Basic Entry')
        end

        it 'returns a CSV with entries lacking optional fields' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: basic_contest_instance.id,
            format: :csv
          }

          expect(response).to be_successful

          csv = CSV.parse(response.body)
          # Check header rows and entry data
          expect(csv.to_s).to include('Basic Entry')
          expect(csv.to_s).to include(profile.user.first_name)
          expect(csv.to_s).to include(profile.user.last_name)
        end
      end
    end

    context 'with container manager user' do
      let(:container_user) { create(:user, :axis_mundi) }  # Make the user axis_mundi
      let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

      before do
        sign_in container_user
      end

      it 'allows export access' do
        get :export_entries, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          format: :csv
        }

        expect(response).to be_successful
        expect(response.content_type).to include('text/csv')
      end
    end

    context 'with unauthorized user' do
      let(:regular_user) { create(:user) }
      let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

      before do
        sign_in regular_user
      end

      it 'denies access to export entries' do
        get :export_entries, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          format: :csv
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end

    context 'with judge user without container role' do
      let(:judge_user) { create(:user) }
      let(:judge_role) { create(:role, :judge) }
      let!(:user_role) { create(:user_role, user: judge_user, role: judge_role) }
      let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

      before do
        # First give the user a judge role, then add as a judge
        contest_instance.judges << judge_user
        sign_in judge_user
      end

      it 'denies access to export entries even for judges' do
        get :export_entries, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          format: :csv
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end
end
