require 'rails_helper'

RSpec.describe ContestInstancesController, type: :controller do
  # Add existing specs if there are any...

  describe 'GET #email_preferences' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) } # Admin user with full privileges
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
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
    let(:contest_description) { create(:contest_description, :active, container: container) }
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
    let(:contest_description) { create(:contest_description, :active, container: container) }

    context 'with authorized users' do
      let(:user) { create(:user, :axis_mundi) }

      before do
        sign_in user
      end

      context 'contest instance with entries' do
        let(:contest_instance) do
          create(:contest_instance, contest_description: contest_description)
        end

        let(:pen_name_question) do
          contest_instance.contest_description.container.application_questions.find_by!(system_key: 'pen_name')
        end

        let(:profile1) { create(:profile, class_level: create(:class_level, name: 'Freshman')) }
        let(:profile2) { create(:profile, class_level: create(:class_level, name: 'Senior')) }
        let(:profile3) { create(:profile, class_level: create(:class_level, name: 'Graduate')) }

        let!(:entry1) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile1,
                 title: 'Entry One').tap do |entry|
            EntryAnswer.create!(entry: entry, application_question: pen_name_question, value: 'Writer One')
          end
        end

        let!(:entry2) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile2,
                 title: 'Entry Two').tap do |entry|
            EntryAnswer.create!(entry: entry, application_question: pen_name_question, value: 'Writer Two')
          end
        end

        let!(:entry3) do
          create(:entry,
                 contest_instance: contest_instance,
                 profile: profile3,
                 disqualified: true,
                 title: 'Entry Three').tap do |entry|
            EntryAnswer.create!(entry: entry, application_question: pen_name_question, value: 'Writer Three')
          end
        end

        before do
          ApplicationQuestionRequirement.create!(
            application_question: pen_name_question,
            requireable: contest_instance,
            status: 'required'
          )
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
          # Skip contest info + blank separator + header row
          data_rows = csv[3..]

          expect(data_rows.length).to eq(3)

          expect(csv.to_s).to include('Entry One')
          expect(csv.to_s).to include('Entry Two')
          expect(csv.to_s).to include('Entry Three')
          expect(csv.to_s).to include('Writer One')
          expect(csv.to_s).to include('Writer Two')
          expect(csv.to_s).to include('Writer Three')

          expect(csv.to_s).to include('Freshman')
          expect(csv.to_s).to include('Senior')
          expect(csv.to_s).to include('Graduate')

          expect(csv.to_s).to include('Yes')
          expect(csv.to_s).to include('No')
        end

        it 'generates CSV with correct structure and headers' do
          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          csv = CSV.parse(response.body)

          expect(csv[0][0]).to include(contest_description.name)
          expect(csv[1].join.strip).to be_empty

          expected_headers = [
            'Title', 'Category', 'First Name', 'Last Name', 'Display Name', 'UMID', 'Uniqname',
            'Class Level', 'Entry ID', 'Created At', 'Disqualified', 'Pen name'
          ]
          expect(csv[2]).to eq(expected_headers)

          entry_row = csv.find { |row| row[0] == 'Entry One' }
          expect(entry_row).not_to be_nil

          expect(entry_row[0]).to eq('Entry One')
          expect(entry_row[2]).to eq(profile1.legal_first_name)
          expect(entry_row[3]).to eq(profile1.legal_last_name)
          expect(entry_row[4]).to eq(profile1.display_name)
          expect(entry_row[5]).to eq(profile1.umid)
          expect(entry_row[6]).to eq(profile1.user.uniqname)
          expect(entry_row[7]).to eq('Freshman')
          expect(entry_row[8]).to eq(entry1.id.to_s)
          expect(entry_row[10]).to eq('No')
          expect(entry_row[11]).to eq('Writer One')

          disqualified_row = csv.find { |row| row[0] == 'Entry Three' }
          expect(disqualified_row).not_to be_nil
          expect(disqualified_row[10]).to eq('Yes')
        end

        it 'neutralizes applicant answers that look like spreadsheet formulas' do
          formula_entry = create(:entry,
                                 contest_instance: contest_instance,
                                 profile: create(:profile),
                                 title: 'Formula Entry')
          EntryAnswer.create!(
            entry: formula_entry,
            application_question: pen_name_question,
            value: '=HYPERLINK("http://evil.example")'
          )

          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          csv = CSV.parse(response.body)
          entry_row = csv.find { |row| row[0] == 'Formula Entry' }

          expect(entry_row).not_to be_nil
          expect(entry_row[11]).to eq("'=HYPERLINK(\"http://evil.example\")")
        end

        it 'neutralizes formula-like entry titles and applicant names' do
          formula_profile = create(
            :profile,
            legal_first_name: '=First',
            legal_last_name: '+Last',
            preferred_first_name: nil,
            preferred_last_name: nil
          )
          create(:entry,
                 contest_instance: contest_instance,
                 profile: formula_profile,
                 title: '@SUM(A1)')

          get :export_entries, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            format: :csv
          }

          csv = CSV.parse(response.body)
          entry_row = csv.find { |row| row[0] == "'@SUM(A1)" }

          expect(entry_row).not_to be_nil
          expect(entry_row[2]).to eq("'=First")
          expect(entry_row[3]).to eq("'+Last")
          expect(entry_row[4]).to eq("'=First +Last")
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
          expect(csv.length).to be >= 3
          expect(csv[3..]).to be_empty if csv.length > 3
        end
      end

      context 'contest instance with entries but no optional fields' do
        let(:basic_contest_instance) do
          create(:contest_instance, contest_description: contest_description)
        end

        let(:profile) { create(:profile) }

        let!(:basic_entry) do
          create(:entry,
                 contest_instance: basic_contest_instance,
                 profile: profile,
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
          expect(csv.to_s).to include('Basic Entry')
          expect(csv.to_s).to include(profile.legal_first_name)
          expect(csv.to_s).to include(profile.legal_last_name)
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

  describe 'GET #export_round_results' do
    let(:department) { create(:department) }
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance, completed: true) }

    context 'with authorized users' do
      let(:user) { create(:user, :axis_mundi) }

      before do
        sign_in user
      end

      context 'with entries and rankings' do
        let(:profile1) { create(:profile) }
        let(:profile2) { create(:profile) }
        let(:judge) { create(:user, :with_judge_role) }
        let!(:entry1) { create(:entry, contest_instance: contest_instance, profile: profile1, title: 'Entry One') }
        let!(:entry2) { create(:entry, contest_instance: contest_instance, profile: profile2, title: 'Entry Two') }

        before do
          # Create judging assignment first
          create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
          create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)

          # Now create rankings
          create(:entry_ranking, entry: entry1, judging_round: judging_round, user: judge, rank: 1, external_comments: 'Great work!')
          create(:entry_ranking, entry: entry2, judging_round: judging_round, user: judge, rank: 2, external_comments: 'Good effort')
        end

        it 'returns a successful CSV response' do
          get :export_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id,
            format: :csv
          }

          expect(response).to be_successful
          expect(response.content_type).to include('text/csv')
          expect(response.headers['Content-Disposition']).to include('attachment')
          expect(response.headers['Content-Disposition']).to include('.csv')
        end

        it 'includes all entries and their rankings in the CSV' do
          get :export_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id,
            format: :csv
          }

          csv = CSV.parse(response.body)

          # Check headers
          expected_headers = ['Entry ID', 'Title', 'Selected for Next Round']
          expected_headers.each do |header|
            expect(csv[2]).to include(header)
          end

          # Check entry data
          expect(csv.to_s).to include('Entry One')
          expect(csv.to_s).to include('Entry Two')
          expect(csv.to_s).to include('Great work!')
          expect(csv.to_s).to include('Good effort')
        end

        it 'neutralizes applicant answers that look like spreadsheet formulas' do
          pen_name_question = contest_instance.contest_description.container.application_questions.find_by!(system_key: 'pen_name')
          ApplicationQuestionRequirement.create!(
            application_question: pen_name_question,
            requireable: contest_instance,
            status: 'required'
          )
          EntryAnswer.create!(
            entry: entry1,
            application_question: pen_name_question,
            value: '=cmd|"/c calc"!A0'
          )

          get :export_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id,
            format: :csv
          }

          csv = CSV.parse(response.body)
          entry_row = csv.find { |row| row[0] == 'Entry One' }

          expect(entry_row).not_to be_nil
          expect(entry_row.last).to eq("'=cmd|\"/c calc\"!A0")
        end

        it 'neutralizes formula-like judge comments' do
          ranking = EntryRanking.find_by!(entry: entry1, judging_round: judging_round, user: judge)
          ranking.update!(
            external_comments: '=HYPERLINK("http://evil.example")',
            internal_comments: '+1-800-evil'
          )

          get :export_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id,
            format: :csv
          }

          csv = CSV.parse(response.body)
          entry_row = csv.find { |row| row[0] == 'Entry One' }

          expect(entry_row).not_to be_nil
          # Title, Category, First, Last, Display, UMID, Uniqname, Class, Entry ID, Selected,
          # Judge Name, Score, External, Internal, then question columns
          expect(entry_row[12]).to eq("'=HYPERLINK(\"http://evil.example\")")
          expect(entry_row[13]).to eq("'+1-800-evil")
        end
      end

      context 'with no entries' do
        it 'returns a CSV with only headers' do
          get :export_round_results, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            id: contest_instance.id,
            round_id: judging_round.id,
            format: :csv
          }

          expect(response).to be_successful
          csv = CSV.parse(response.body)
          # The CSV should have 3 rows: contest info, empty row, and headers
          expect(csv.length).to eq(3)
          expect(csv[0][0]).to include(contest_description.name) # Contest info
          expect(csv[1].join.strip).to be_empty # Empty row
          expect(csv[2]).to include('Entry ID', 'Title', 'Selected for Next Round')
        end
      end
    end

    context 'with non-existent judging round' do
      let(:user) { create(:user, :axis_mundi) }

      before do
        sign_in user
      end

      it 'redirects with an alert' do
        get :export_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: 9999,
          format: :csv
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_path(container, contest_description, contest_instance))
        expect(flash[:alert]).to eq('Judging round not found.')
      end
    end

    context 'with unauthorized user' do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it 'denies access to export round results' do
        get :export_round_results, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          round_id: judging_round.id,
          format: :csv
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/not authorized/i)
      end
    end
  end

  describe 'PATCH #update' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) }
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:question) { container.application_questions.find_by!(system_key: 'pen_name') }

    before { sign_in user }

    it 'syncs application question requirements for the contest instance' do
      patch :update, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        contest_instance: { notes: 'Updated notes' },
        requirements: {
          question.id.to_s => { status: 'optional', position: '2' }
        }
      }

      requirement = ApplicationQuestionRequirement.find_by!(
        application_question: question,
        requireable: contest_instance
      )
      expect(requirement.status).to eq('optional')
      expect(requirement.position).to eq(2)
      expect(response).to redirect_to(
        container_contest_description_contest_instance_path(container, contest_description, contest_instance)
      )
    end

    it 'clears contest instance requirements when status is inherit' do
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: contest_instance,
        status: 'required'
      )

      patch :update, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        contest_instance: { notes: 'Updated notes' },
        requirements: {
          question.id.to_s => { status: 'inherit' }
        }
      }

      expect(
        ApplicationQuestionRequirement.where(
          application_question: question,
          requireable: contest_instance
        )
      ).to be_empty
    end

    it 'ignores requirements for questions outside the container' do
      other_question = create(:container).application_questions.find_by!(system_key: 'pen_name')

      expect {
        patch :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          contest_instance: { notes: 'Updated notes' },
          requirements: {
            other_question.id.to_s => { status: 'required' }
          }
        }
      }.not_to change(ApplicationQuestionRequirement, :count)
    end
  end

  describe 'GET #show sorting' do
    let(:department) { create(:department) }
    let(:user) { create(:user, :axis_mundi) }
    let(:container) { create(:container, department: department) }
    let(:contest_description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

    before { sign_in user }

    it 'orders entries by preferred last name when sorting by applicant name' do
      # First names and titles sort opposite of last names, so a regression
      # that ordered by either of those columns would fail this example.
      zebra_profile = create(:profile, preferred_first_name: 'Ann', preferred_last_name: 'Zebra')
      alpha_profile = create(:profile, preferred_first_name: 'Zoe', preferred_last_name: 'Alpha')
      create(:entry, contest_instance: contest_instance, profile: zebra_profile, title: 'Alpha Entry')
      create(:entry, contest_instance: contest_instance, profile: alpha_profile, title: 'Zebra Entry')

      get :show, params: {
        container_id: container.id,
        contest_description_id: contest_description.id,
        id: contest_instance.id,
        sort_column: 'profile_display_name',
        sort_direction: 'asc'
      }

      expect(assigns(:contest_instance_entries).map { |entry| entry.profile.display_name })
        .to eq([ 'Zoe Alpha', 'Ann Zebra' ])
    end

    it 'ignores unknown sort columns' do
      create(:entry, contest_instance: contest_instance, title: 'Only Entry')

      expect {
        get :show, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          id: contest_instance.id,
          sort_column: 'not_a_real_column',
          sort_direction: 'asc'
        }
      }.not_to raise_error

      expect(assigns(:contest_instance_entries).map(&:title)).to include('Only Entry')
    end
  end
end
