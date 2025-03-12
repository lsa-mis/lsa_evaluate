require 'rails_helper'

RSpec.describe ResultsMailer, type: :mailer do
  describe '#entry_evaluation_notification' do
    # Create all required test data
    let(:user) { create(:user, email: 'applicant@example.com', first_name: 'John', last_name: 'Applicant') }
    let(:profile) { create(:profile, user: user) }
    let(:department) { create(:department) }
    let(:container) { create(:container, name: 'Test Container', department: department, contact_email: 'contact@example.com') }
    let(:contest_description) { create(:contest_description, name: 'Test Contest', container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description, date_open: 2.months.ago, date_closed: 1.month.ago) }
    let(:category) { create(:category, kind: 'Poetry') }
    let(:entry) { create(:entry, title: 'Test Entry', profile: profile, contest_instance: contest_instance, category: category, pen_name: 'Writer Pen') }
    # Create a second entry for the second ranking
    let(:entry2) { create(:entry, title: 'Second Entry', profile: profile, contest_instance: contest_instance, category: category, pen_name: 'Writer Pen') }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance, round_number: 1, completed: true,
                                start_date: 3.weeks.ago, end_date: 2.weeks.ago) }
    let(:judge) { create(:user, :with_judge_role) }

    # Create the judging assignment to link the judge to the contest
    let!(:judging_assignment) { create(:judging_assignment, user: judge, contest_instance: contest_instance) }
    # Assign judge to the round
    let!(:round_judge_assignment) { create(:round_judge_assignment, user: judge, judging_round: judging_round) }

    # Create test rankings - using different entries
    let!(:ranking1) { create(:entry_ranking, entry: entry, user: judge, judging_round: judging_round, rank: 1, external_comments: 'Great work!', selected_for_next_round: true) }
    let!(:ranking2) { create(:entry_ranking, entry: entry2, user: judge, judging_round: judging_round, rank: 2, external_comments: 'Impressive submission.') }

    let(:mail) { described_class.entry_evaluation_notification(entry, judging_round) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Evaluation Results for \"Test Entry\" - Test Contest")
      expect(mail.to).to eq([ 'applicant@example.com' ])
      expect(mail.from).to eq([ Rails.application.credentials.dig(:devise, :mailer_sender) || 'from@example.com' ])
    end

    it 'renders the entry details in the body' do
      expect(mail.body.encoded).to include('Test Entry')
      expect(mail.body.encoded).to include('Category: Poetry')
      expect(mail.body.encoded).to include('Pen Name: Writer Pen')
    end

    it 'includes the average ranking' do
      # We'll use only ranking1 since it's the one for our entry
      expect(mail.body.encoded).to include('average ranking of 1')
    end

    it 'includes the external comments' do
      expect(mail.body.encoded).to include('Great work!')
      expect(mail.body.encoded).not_to include('Impressive submission.') # This is for entry2
    end

    it 'indicates the entry was selected for the next round' do
      expect(mail.body.encoded).to include('Congratulations')
      expect(mail.body.encoded).to include('has been selected')
    end

    it 'includes the contact email' do
      expect(mail.body.encoded).to include('contact@example.com')
    end

    context 'when container has no contact email' do
      # Use allow to bypass the validation rather than trying to create an invalid container
      before do
        # Mock the container's contact_email method to return nil or empty string
        allow_any_instance_of(Container).to receive(:contact_email).and_return(nil)
      end

      it 'falls back to the default contact email from credentials' do
        default_email = Rails.application.credentials.dig(:mailer, :default_contact_email)

        if default_email
          expect(mail.body.encoded).to include(default_email)
        else
          default_sender = Rails.application.credentials.dig(:devise, :mailer_sender) || 'contests@example.com'
          expect(mail.body.encoded).to include(default_sender)
        end
      end
    end

    context 'when entry was not selected for next round' do
      # Use the same approach with the judge
      before do
        # Update the existing ranking to be not selected for next round
        ranking1.update_column(:selected_for_next_round, false)
      end

      it 'indicates the entry was not selected' do
        expect(mail.body.encoded).to include('regret to inform you')
        expect(mail.body.encoded).to include('not selected')
      end
    end

    context 'when there are no external comments' do
      before do
        # Update the existing ranking to have no external comments
        ranking1.update_column(:external_comments, '')
      end

      it 'does not include the feedback section' do
        expect(mail.body.encoded).not_to include('Feedback from Judges')
      end
    end

    context 'when it is the final round' do
      # Make sure the final round dates come after the first round end date
      let(:final_round) { create(:judging_round, contest_instance: contest_instance, round_number: 2, completed: true,
                                start_date: 1.week.ago, end_date: 2.days.ago) }

      before do
        # Assign the same judge to the final round
        create(:round_judge_assignment, user: judge, judging_round: final_round)
        # Create a ranking in the final round
        create(:entry_ranking, entry: entry, user: judge, judging_round: final_round, rank: 1, selected_for_next_round: true)
        # Allow the method call that checks for maximum round number
        allow(contest_instance.judging_rounds).to receive(:maximum).with(:round_number).and_return(2)
        # Use the final round for the mailer
        @mail = described_class.entry_evaluation_notification(entry, final_round)
      end

      it 'indicates the entry is a finalist' do
        expect(@mail.body.encoded).to include('selected as a finalist')
      end
    end
  end
end
