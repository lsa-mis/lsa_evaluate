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
    create(:assignment, user: admin, container: container, role: container_admin_role)
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
      let(:empty_round) { create(:judging_round, contest_instance: contest_instance) }

      it 'redirects with an alert' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: empty_round.id
        }
        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
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
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id
          }
          perform_enqueued_jobs

          expect(round_assignment1.reload.instructions_sent_at).to be_within(1.second).of(Time.current)
          expect(round_assignment2.reload.instructions_sent_at).to be_within(1.second).of(Time.current)
          expect(round_assignment3.reload.instructions_sent_at).to be_within(1.second).of(Time.current)
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
          post :send_instructions, params: {
            container_id: container.id,
            contest_description_id: contest_description.id,
            contest_instance_id: contest_instance.id,
            id: judging_round.id,
            judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
          }
          perform_enqueued_jobs

          expect(round_assignment1.reload.instructions_sent_at).to be_within(1.second).of(Time.current)
          expect(round_assignment3.reload.instructions_sent_at).to be_within(1.second).of(Time.current)
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
      it 'redirects with an alert' do
        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          judge_assignment_ids: []
        }

        expect(response).to redirect_to(container_contest_description_contest_instance_judging_assignments_path(
          container, contest_description, contest_instance
        ))
        expect(flash[:alert]).to eq('No judges selected.')
      end
    end

    context 'when sending with container administrator CC' do
      let(:container_admin1) { create(:user, email: 'admin1@umich.edu') }
      let(:container_admin2) { create(:user, email: 'admin2@umich.edu') }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: container_admin1, container: container, role: admin_role)
        create(:assignment, user: container_admin2, container: container, role: admin_role)
      end

      it 'includes collection administrators in CC' do
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment1,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu']
        )
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment2,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu']
        )
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment3,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu']
        )

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          send_copy_to_admin: '1'
        }
      end

      it 'normalizes admin emails with plus signs' do
        container_admin3 = create(:user, email: 'admin3+tag@umich.edu')
        create(:assignment, user: container_admin3, container: container, role: admin_role)

        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment1,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu', 'admin3@umich.edu']
        )

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          send_copy_to_admin: '1',
          judge_assignment_ids: [round_assignment1.id]
        }
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
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment1,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu']
        )
        expect(JudgingInstructionsMailer).to receive(:send_instructions).with(
          round_assignment3,
          cc_emails: ['admin1@umich.edu', 'admin2@umich.edu']
        )
        expect(JudgingInstructionsMailer).not_to receive(:send_instructions).with(round_assignment2, anything)

        post :send_instructions, params: {
          container_id: container.id,
          contest_description_id: contest_description.id,
          contest_instance_id: contest_instance.id,
          id: judging_round.id,
          send_copy_to_admin: '1',
          judge_assignment_ids: [round_assignment1.id, round_assignment3.id]
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
      let!(:inactive_assignment) do
        create(:round_judge_assignment, :inactive, user: judge3, judging_round: judging_round)
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
  end
end
