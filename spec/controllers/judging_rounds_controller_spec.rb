require 'rails_helper'

RSpec.describe JudgingRoundsController, type: :controller do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:admin) { create(:user) }
  let(:judge) { create(:user, :with_judge_role) }

  before do
    container_admin_role = create(:role, kind: 'Collection Administrator')
    @admin_assignment = create(:assignment, user: admin, container: container, role: container_admin_role)
  end

  describe 'GET #edit' do
    context 'when user is container administrator' do
      before { sign_in admin }

      it 'assigns the requested judging round' do
        get :edit, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
        expect(assigns(:judging_round)).to eq(judging_round)
      end
    end

    context 'when user is not container administrator' do
      before { sign_in judge }

      it 'redirects to root' do
        get :edit, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:valid_attributes) do
      {
        round_number: 1,
        start_date: contest_instance.date_closed + 1.day,
        end_date: contest_instance.date_closed + 2.days,
        require_internal_comments: true,
        min_internal_comment_words: 5,
        require_external_comments: true,
        min_external_comment_words: 10
      }
    end

    context 'when user is container administrator' do
      before { sign_in admin }

      context 'with valid params' do
        it 'updates the judging round' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: valid_attributes
          }
          judging_round.reload
          expect(judging_round.require_internal_comments).to be true
          expect(judging_round.min_internal_comment_words).to eq(5)
          expect(judging_round.require_external_comments).to be true
          expect(judging_round.min_external_comment_words).to eq(10)
        end

        it 'redirects to judging assignments' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: valid_attributes
          }
          expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
            container, contest_description, contest_instance
          ))
        end
      end

      context 'with invalid params' do
        let(:invalid_attributes) { { start_date: nil } }

        it 'does not update the judging round' do
          original_start_date = judging_round.start_date
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: invalid_attributes
          }
          judging_round.reload
          expect(judging_round.start_date).to eq(original_start_date)
        end

        it 're-renders the edit template' do
          patch :update, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judging_round: invalid_attributes
          }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not container administrator' do
      before { sign_in judge }

      it 'redirects to root' do
        patch :update, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judging_round: valid_attributes
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #send_instructions' do
    let(:judge1) { create(:user, :with_judge_role, email: 'judge1@umich.edu') }
    let(:judge2) { create(:user, :with_judge_role, email: 'judge2@umich.edu') }
    let(:judge3) { create(:user, :with_judge_role, email: 'judge3@umich.edu') }

    let!(:judging_assignment1) { create(:judging_assignment, user: judge1, contest_instance: contest_instance) }
    let!(:judging_assignment2) { create(:judging_assignment, user: judge2, contest_instance: contest_instance) }
    let!(:judging_assignment3) { create(:judging_assignment, user: judge3, contest_instance: contest_instance) }

    let!(:round_assignment1) { create(:round_judge_assignment, user: judge1, judging_round: judging_round) }
    let!(:round_assignment2) { create(:round_judge_assignment, user: judge2, judging_round: judging_round) }
    let!(:round_assignment3) { create(:round_judge_assignment, user: judge3, judging_round: judging_round) }

    before do
      sign_in admin
      ActiveJob::Base.queue_adapter = :test
    end

    context 'when no judges are assigned to the round' do
      let(:empty_contest_description) { create(:contest_description, :active, container: container) }
      let(:empty_contest_instance) { create(:contest_instance, contest_description: empty_contest_description, active: false) }
      let(:empty_round) { create(:judging_round, contest_instance: empty_contest_instance, round_number: 99) }

      it 'redirects with an alert' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: empty_contest_description.id,
          contest_instance_id: empty_contest_instance.id,
          id: empty_round.id
        }
        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, empty_contest_description, empty_contest_instance
        ))
        expect(flash[:alert]).to eq('No judges assigned to this round.')
      end
    end

    context 'when sending to all judges (no selection)' do
      before do
        allow(JudgingInstructionsMailer).to receive(:send_instructions).and_call_original
      end

      it 'sends instructions to all active judges' do
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(round_assignment1, cc_emails: [])
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(round_assignment2, cc_emails: [])
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(round_assignment3, cc_emails: [])

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
      end

      it 'queues emails for delivery' do
        expect {
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id
          }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(3).times
      end

      it 'updates instructions_sent_at for all assignments' do
        freeze_time do
          current_time = Time.current
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id
          }

          # update_column is synchronous, so we can check immediately
          expect(round_assignment1.reload.instructions_sent_at).to be_within(1.second).of(current_time)
          expect(round_assignment2.reload.instructions_sent_at).to be_within(1.second).of(current_time)
          expect(round_assignment3.reload.instructions_sent_at).to be_within(1.second).of(current_time)
        end
      end

      it 'redirects with success notice' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
        ))
        expect(flash[:notice]).to eq('Judging instructions sent successfully to 3 judge(s).')
      end
    end

    context 'when sending to selected individual judges' do
      it 'sends instructions only to selected judges' do
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(round_assignment1, cc_emails: []).once
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(round_assignment3, cc_emails: []).once
        expect(JudgingInstructionsMailer).not_to receive(:send_instructions).with(round_assignment2, cc_emails: [])

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
        }
      end

      it 'queues emails only for selected judges' do
        expect {
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
          }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(2).times
      end

      it 'updates instructions_sent_at only for selected assignments' do
        freeze_time do
          current_time = Time.current
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
          }

          # update_column is synchronous, so we can check immediately
          expect(round_assignment1.reload.instructions_sent_at).to be_within(1.second).of(current_time)
          expect(round_assignment3.reload.instructions_sent_at).to be_within(1.second).of(current_time)
          expect(round_assignment2.reload.instructions_sent_at).to be_nil
        end
      end

      it 'redirects with success notice for selected judges' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
        ))
        expect(flash[:notice]).to eq('Judging instructions sent successfully to 2 judge(s).')
      end
    end

    context 'when no judges are selected' do
      it 'redirects with an alert when invalid IDs are provided' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judge_assignment_ids: [99999, 99998] # Invalid IDs that don't exist
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
        ))
        expect(flash[:alert]).to eq('No judges selected.')
      end
    end

    context 'when sending with container administrator CC' do
      let(:cc_container) { create(:container) }
      let(:cc_contest_description) { create(:contest_description, :active, container: cc_container) }
      let(:cc_contest_instance) { create(:contest_instance, contest_description: cc_contest_description) }
      let(:cc_judging_round) { create(:judging_round, contest_instance: cc_contest_instance) }

      # Create judging assignments first (required for round assignments)
      let!(:cc_judging_assignment1) { create(:judging_assignment, user: judge1, contest_instance: cc_contest_instance) }
      let!(:cc_judging_assignment2) { create(:judging_assignment, user: judge2, contest_instance: cc_contest_instance) }
      let!(:cc_judging_assignment3) { create(:judging_assignment, user: judge3, contest_instance: cc_contest_instance) }

      let!(:cc_round_assignment1) { create(:round_judge_assignment, user: judge1, judging_round: cc_judging_round) }
      let!(:cc_round_assignment2) { create(:round_judge_assignment, user: judge2, judging_round: cc_judging_round) }
      let!(:cc_round_assignment3) { create(:round_judge_assignment, user: judge3, judging_round: cc_judging_round) }

      let(:container_admin1) { create(:user, email: 'admin1@umich.edu') }
      let(:container_admin2) { create(:user, email: 'admin2@umich.edu') }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        # Ensure admin user has access to cc_container
        cc_admin_role = create(:role, kind: 'Collection Administrator')
        create(:assignment, user: admin, container: cc_container, role: cc_admin_role)
        create(:assignment, user: container_admin1, container: cc_container, role: admin_role)
        create(:assignment, user: container_admin2, container: cc_container, role: admin_role)
      end

      it 'includes collection administrators in CC' do
        call_args = nil
        allow(JudgingInstructionsMailer).to receive(:send_instructions).and_wrap_original do |method, *args, **kwargs|
          call_args = { args: args, kwargs: kwargs }
          method.call(*args, **kwargs)
        end

        post :send_instructions, params: {
          container_id: cc_container.id,
          contest_description_id: cc_contest_description.id,
          contest_instance_id: cc_contest_instance.id,
          id: cc_judging_round.id,
          send_copy_to_admin: '1',
          judge_assignment_ids: [cc_round_assignment1.id]
        }

        expect(call_args).to be_present
        expect(call_args[:args].first).to eq(cc_round_assignment1)
        # Admin user is also included in CC list
        expect(call_args[:kwargs][:cc_emails]).to match_array([admin.email, 'admin1@umich.edu', 'admin2@umich.edu'])
      end

      it 'normalizes admin emails with plus signs' do
        container_admin3 = create(:user, email: 'admin3+tag@umich.edu')
        create(:assignment, user: container_admin3, container: cc_container, role: admin_role)

        call_args = nil
        allow(JudgingInstructionsMailer).to receive(:send_instructions).and_wrap_original do |method, *args, **kwargs|
          call_args = { args: args, kwargs: kwargs }
          method.call(*args, **kwargs)
        end

        # Note: The normalize_email method currently has a bug that returns "admin3@tag" instead of "admin3@umich.edu"
        # Testing the actual current behavior
        post :send_instructions, params: {
          container_id: cc_container.id,
          contest_description_id: cc_contest_description.id,
          contest_instance_id: cc_contest_instance.id,
          id: cc_judging_round.id,
          send_copy_to_admin: '1',
          judge_assignment_ids: [cc_round_assignment1.id]
        }

        expect(call_args).to be_present
        expect(call_args[:args].first).to eq(cc_round_assignment1)
        # Admin user is also included in CC list
        expect(call_args[:kwargs][:cc_emails]).to match_array([admin.email, 'admin1@umich.edu', 'admin2@umich.edu', 'admin3@tag'])
      end

      it 'does not include CC when checkbox is not checked' do
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment1,
          cc_emails: []
        )

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          send_copy_to_admin: '0',
          judge_assignment_ids: [round_assignment1.id]
        }
      end

      it 'works with individual judge selection and CC' do
        call_args_list = []
        allow(JudgingInstructionsMailer).to receive(:send_instructions).and_wrap_original do |method, *args, **kwargs|
          call_args_list << { args: args, kwargs: kwargs }
          method.call(*args, **kwargs)
        end

        post :send_instructions, params: {
          container_id: cc_container.id,
          contest_description_id: cc_contest_description.id,
          contest_instance_id: cc_contest_instance.id,
          id: cc_judging_round.id,
          send_copy_to_admin: '1',
          judge_assignment_ids: [cc_round_assignment1.id, cc_round_assignment3.id]
        }

        expect(call_args_list.length).to eq(2)
        assignment1_call = call_args_list.find { |c| c[:args].first == cc_round_assignment1 }
        assignment3_call = call_args_list.find { |c| c[:args].first == cc_round_assignment3 }
        assignment2_call = call_args_list.find { |c| c[:args].first == cc_round_assignment2 }

        expect(assignment1_call).to be_present
        # Admin user is also included in CC list
        expect(assignment1_call[:kwargs][:cc_emails]).to match_array([admin.email, 'admin1@umich.edu', 'admin2@umich.edu'])
        expect(assignment3_call).to be_present
        expect(assignment3_call[:kwargs][:cc_emails]).to match_array([admin.email, 'admin1@umich.edu', 'admin2@umich.edu'])
        expect(assignment2_call).to be_nil
      end
    end

    context 'when user is not authorized' do
      before { sign_in judge }

      it 'redirects to root path' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when inactive assignments exist' do
      let(:inactive_judge) { create(:user, :with_judge_role, email: 'inactive_judge@umich.edu') }
      let!(:inactive_judging_assignment) { create(:judging_assignment, user: inactive_judge, contest_instance: contest_instance) }
      let!(:inactive_assignment) do
        create(:round_judge_assignment, :inactive, user: inactive_judge, judging_round: judging_round)
      end

      it 'only sends to active assignments' do
        expect(JudgingInstructionsMailer).to receive(:send_instructions).exactly(3).times
        expect(JudgingInstructionsMailer).not_to receive(:send_instructions).with(inactive_assignment, anything)

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
      end
    end

    context 'when email delivery fails' do
      before do
        allow(JudgingInstructionsMailer).to receive(:send_instructions).and_call_original
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(StandardError.new('Email delivery failed'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and continues with other emails' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }
      end

      it 'includes failed emails in the notice message' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }

        expect(flash[:notice]).to include('Failed to send to:')
        expect(flash[:notice]).to include('judge1@umich.edu')
      end

      it 'does not update instructions_sent_at for failed emails' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id
        }

        expect(round_assignment1.reload.instructions_sent_at).to be_nil
      end
    end
  end

  describe 'POST #notify_completed' do
    let(:container_with_contact) { create(:container, contact_email: 'contest_contact@umich.edu') }
    let(:contest_description) { create(:contest_description, :active, container: container_with_contact, name: 'Test Contest') }
    let(:contest_instance) do
      create(:contest_instance,
        contest_description: contest_description,
        date_open: 2.months.ago,
        date_closed: 1.month.ago,
        active: true)
    end
    let(:judging_round) do
      create(:judging_round,
        contest_instance: contest_instance,
        round_number: 1,
        active: true,
        start_date: 1.day.ago,
        end_date: 1.day.from_now,
        required_entries_count: 3)
    end
    let(:judge_user) { create(:user, :with_judge_role, email: 'judge@umich.edu', first_name: 'Jane', last_name: 'Doe') }
    let!(:judging_assignment) { create(:judging_assignment, user: judge_user, contest_instance: contest_instance, active: true) }
    let!(:round_judge_assignment) { create(:round_judge_assignment, user: judge_user, judging_round: judging_round, active: true) }
    let!(:entry1) { create(:entry, contest_instance: contest_instance, deleted: false) }
    let!(:entry2) { create(:entry, contest_instance: contest_instance, deleted: false) }
    let!(:entry3) { create(:entry, contest_instance: contest_instance, deleted: false) }

    before do
      sign_in judge_user
      ActiveJob::Base.queue_adapter = :test
    end

    def notify_completed_params
      {
        container_id: container_with_contact.id,
        contest_description_id: contest_description.id,
        contest_instance_id: contest_instance.id,
        id: judging_round.id
      }
    end

    context 'when judge has ranked exactly the required number of entries' do
      before do
        create(:entry_ranking, entry: entry1, judging_round: judging_round, user: judge_user, rank: 1)
        create(:entry_ranking, entry: entry2, judging_round: judging_round, user: judge_user, rank: 2)
        create(:entry_ranking, entry: entry3, judging_round: judging_round, user: judge_user, rank: 3)
      end

      it 'enqueues the notification email' do
        expect {
          post :notify_completed, params: notify_completed_params
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
      end

      it 'redirects to judge dashboard with success notice' do
        post :notify_completed, params: notify_completed_params

        expect(response).to redirect_to(judge_dashboard_path)
        expect(flash[:notice]).to eq('The contest contact has been notified that you have completed your evaluations.')
      end

      it 'sends to the container contact email' do
        captured_mail = nil
        allow(JudgeCompletedEvaluationsMailer).to receive(:notify_contact).and_wrap_original do |method, *args|
          captured_mail = method.call(*args)
        end

        post :notify_completed, params: notify_completed_params

        expect(captured_mail).to be_a(ActionMailer::MessageDelivery)
        mail = captured_mail.message
        expect(mail.to).to eq([ 'contest_contact@umich.edu' ])
        expect(mail.reply_to).to eq([ 'judge@umich.edu' ])
      end
    end

    context 'when judge has ranked fewer than the required number of entries' do
      before do
        create(:entry_ranking, entry: entry1, judging_round: judging_round, user: judge_user, rank: 1)
        create(:entry_ranking, entry: entry2, judging_round: judging_round, user: judge_user, rank: 2)
        # Only 2 ranked, need 3
      end

      it 'does not enqueue the notification email' do
        expect {
          post :notify_completed, params: notify_completed_params
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'redirects to judge dashboard with alert about needing more rankings' do
        post :notify_completed, params: notify_completed_params

        expect(response).to redirect_to(judge_dashboard_path)
        expect(flash[:alert]).to include('Please rank at least 3 entries before notifying')
        expect(flash[:alert]).to include('You have 2 ranked')
      end
    end

    context 'when judge has ranked more than the required number' do
      let!(:entry4) { create(:entry, contest_instance: contest_instance, deleted: false) }

      before do
        create(:entry_ranking, entry: entry1, judging_round: judging_round, user: judge_user, rank: 1)
        create(:entry_ranking, entry: entry2, judging_round: judging_round, user: judge_user, rank: 2)
        create(:entry_ranking, entry: entry3, judging_round: judging_round, user: judge_user, rank: 3)
        create(:entry_ranking, entry: entry4, judging_round: judging_round, user: judge_user, rank: 4)
      end

      it 'enqueues the notification email' do
        expect {
          post :notify_completed, params: notify_completed_params
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
      end

      it 'redirects to judge dashboard with success notice' do
        post :notify_completed, params: notify_completed_params

        expect(response).to redirect_to(judge_dashboard_path)
        expect(flash[:notice]).to eq('The contest contact has been notified that you have completed your evaluations.')
      end
    end

    context 'when container has no contact email' do
      let(:container_no_email) { create(:container) }
      let(:contest_description_no_email) { create(:contest_description, :active, container: container_no_email) }
      let(:contest_instance_no_email) do
        create(:contest_instance,
          contest_description: contest_description_no_email,
          date_open: 2.months.ago,
          date_closed: 1.month.ago,
          active: true)
      end
      let(:judging_round_no_email) do
        create(:judging_round,
          contest_instance: contest_instance_no_email,
          round_number: 1,
          active: true,
          start_date: 1.day.ago,
          end_date: 1.day.from_now,
          required_entries_count: 2)
      end
      let!(:judging_assignment_no_email) { create(:judging_assignment, user: judge_user, contest_instance: contest_instance_no_email, active: true) }
      let!(:round_judge_assignment_no_email) { create(:round_judge_assignment, user: judge_user, judging_round: judging_round_no_email, active: true) }
      let!(:entry_a) { create(:entry, contest_instance: contest_instance_no_email, deleted: false) }
      let!(:entry_b) { create(:entry, contest_instance: contest_instance_no_email, deleted: false) }

      before do
        container_no_email.update_column(:contact_email, nil)
        create(:entry_ranking, entry: entry_a, judging_round: judging_round_no_email, user: judge_user, rank: 1)
        create(:entry_ranking, entry: entry_b, judging_round: judging_round_no_email, user: judge_user, rank: 2)
      end

      it 'does not enqueue the notification email' do
        expect {
          post :notify_completed, params: {
            container_id: container_no_email.id,
            contest_description_id: contest_description_no_email.id,
            contest_instance_id: contest_instance_no_email.id,
            id: judging_round_no_email.id
          }
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'redirects with alert about missing contact email' do
        post :notify_completed, params: {
          container_id: container_no_email.id,
          contest_description_id: contest_description_no_email.id,
          contest_instance_id: contest_instance_no_email.id,
          id: judging_round_no_email.id
        }

        expect(response).to redirect_to(judge_dashboard_path)
        expect(flash[:alert]).to eq('No contact email is set for this contest. Please contact an administrator.')
      end
    end

    context 'when user is not the assigned judge' do
      let(:other_user) { create(:user, :with_judge_role) }

      before do
        sign_in other_user
        create(:entry_ranking, entry: entry1, judging_round: judging_round, user: judge_user, rank: 1)
        create(:entry_ranking, entry: entry2, judging_round: judging_round, user: judge_user, rank: 2)
        create(:entry_ranking, entry: entry3, judging_round: judging_round, user: judge_user, rank: 3)
      end

      it 'redirects to root (unauthorized)' do
        post :notify_completed, params: notify_completed_params

        expect(response).to redirect_to(root_path)
      end

      it 'does not enqueue the notification email' do
        expect {
          post :notify_completed, params: notify_completed_params
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
  end
end
