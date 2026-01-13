require 'rails_helper'

RSpec.describe JudgingInstructionsMailer, type: :mailer do
  describe '#send_instructions' do
    let(:container) { create(:container, contact_email: 'contest_admin@umich.edu') }
    let(:contest_description) { create(:contest_description, :active, container: container, name: 'Test Contest') }
    let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
    let(:judging_round) do
      create(:judging_round,
             contest_instance: contest_instance,
             round_number: 2,
             special_instructions: 'Please evaluate entries based on creativity and originality.',
             required_entries_count: 5,
             require_internal_comments: true,
             min_internal_comment_words: 50,
             require_external_comments: true,
             min_external_comment_words: 100)
    end
    let(:judge) { create(:user, :with_judge_role, email: 'judge@umich.edu', first_name: 'Jane', last_name: 'Doe') }
    let(:round_judge_assignment) { create(:round_judge_assignment, :with_contest_assignment, user: judge, judging_round: judging_round) }

    let(:mail) { described_class.send_instructions(round_judge_assignment) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Judging Instructions for Test Contest - Round 2")
      expect(mail.to).to eq(['judge@umich.edu'])
      expect(mail.from).to include(Rails.application.credentials.dig(:sendgrid, :mailer_sender))
    end

        it 'uses the container contact email as reply-to when present' do
      expect(mail.reply_to).to eq([ 'contest_admin@umich.edu' ])
    end

    it 'falls back to default reply-to when container contact email is not present' do
      # Create a new container without contact_email by overriding validation
      container_without_email = container
      container_without_email.contact_email = ''
      container_without_email.save(validate: false)
      contest_description.update!(container: container_without_email)

      # Need to regenerate the mail with the updated container
      mail_without_contact = described_class.send_instructions(round_judge_assignment)
      # When no container email is set, it should use ApplicationMailer's default
      expect(mail_without_contact.reply_to).to eq([ 'lsa-evaluate-support@umich.edu' ])
    end

    describe 'email body' do
      it 'includes judge name' do
        expect(mail.body.encoded).to include('Jane Doe')
      end

      it 'includes contest name and round number' do
        expect(mail.body.encoded).to include('Test Contest')
        expect(mail.body.encoded).to include('Round 2')
      end

      it 'includes judging period dates' do
        expect(mail.body.encoded).to include(I18n.l(judging_round.start_date, format: :long))
        expect(mail.body.encoded).to include(I18n.l(judging_round.end_date, format: :long))
      end

      it 'includes special instructions' do
        expect(mail.body.encoded).to include('Please evaluate entries based on creativity and originality.')
      end

      it 'includes requirements' do
        expect(mail.body.encoded).to include('5') # required_entries_count
        expect(mail.body.encoded).to include('50') # min_internal_comment_words
        expect(mail.body.encoded).to include('100') # min_external_comment_words
      end

      it 'includes link to judging dashboard' do
        expect(mail.body.encoded).to include(judge_dashboard_index_url)
      end

      it 'includes contact email' do
        expect(mail.body.encoded).to include('contest_admin@umich.edu')
      end

      it 'shows default contact email when container email is not present' do
        container.contact_email = ''
        container.save(validate: false)
        contest_description.reload

        mail_without_contact = described_class.send_instructions(round_judge_assignment)
        expect(mail_without_contact.body.encoded).to include('lsa-evaluate-support@umich.edu')
      end
    end

    context 'when special instructions are not present' do
      before do
        judging_round.update!(special_instructions: nil)
      end

      it 'does not include the special instructions section' do
        # Check both parts of the multipart email
        html_part = mail.html_part ? mail.html_part.body.to_s : mail.body.to_s
        text_part = mail.text_part ? mail.text_part.body.to_s : mail.body.to_s

        expect(html_part).not_to include('Special Instructions')
        expect(text_part).not_to include('SPECIAL INSTRUCTIONS')
      end
    end

    context 'when comment requirements are not present' do
      before do
        judging_round.update!(require_internal_comments: false, require_external_comments: false)
      end

      it 'does not include comment requirements' do
        expect(mail.body.encoded).not_to include('Internal comments:')
        expect(mail.body.encoded).not_to include('External comments:')
      end
    end

    context 'when CC emails are provided' do
      let(:cc_emails) { ['admin1@umich.edu', 'admin2@umich.edu'] }

      it 'includes CC recipients in the email' do
        mail_with_cc = described_class.send_instructions(round_judge_assignment, cc_emails: cc_emails)
        expect(mail_with_cc.cc).to match_array(cc_emails)
      end

      it 'still sends the primary email to the judge' do
        mail_with_cc = described_class.send_instructions(round_judge_assignment, cc_emails: cc_emails)
        expect(mail_with_cc.to).to eq(['judge@umich.edu'])
      end

      it 'maintains all other email properties' do
        mail_with_cc = described_class.send_instructions(round_judge_assignment, cc_emails: cc_emails)
        expect(mail_with_cc.subject).to eq("Judging Instructions for Test Contest - Round 2")
        expect(mail_with_cc.reply_to).to eq([ 'contest_admin@umich.edu' ])
      end
    end

    context 'when no CC emails are provided' do
      it 'does not include CC field' do
        expect(mail.cc).to be_nil
      end
    end

    context 'when empty CC emails array is provided' do
      it 'does not include CC field' do
        mail_with_empty_cc = described_class.send_instructions(round_judge_assignment, cc_emails: [])
        expect(mail_with_empty_cc.cc).to be_nil
      end
    end
  end
end
