# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInviteMailer, type: :mailer do
  describe '#invite_to_submit' do
    let(:container) { create(:container, :private, contact_email: 'contest_admin@umich.edu') }
    let(:contest_description) do
      create(:contest_description, :active, container: container, name: 'Private Writing Prize')
    end
    let(:contest_instance) { create(:contest_instance, :invite_list, contest_description: contest_description) }
    let(:invitation) do
      create(:contest_invitation, contest_instance: contest_instance, email: 'invitee@umich.edu')
    end
    let(:mail) { described_class.invite_to_submit(invitation) }

    it 'renders the headers' do
      expect(mail.subject).to eq("You're invited to submit: Private Writing Prize")
      expect(mail.to).to eq([ 'invitee@umich.edu' ])
      expect(mail.from).to include(Rails.application.credentials.dig(:sendgrid, :mailer_sender))
      expect(mail.reply_to).to eq([ 'contest_admin@umich.edu' ])
    end

    it 'includes the contest name and collection name' do
      expect(mail.body.encoded).to include('Private Writing Prize')
      expect(mail.body.encoded).to include(container.name)
    end

    it 'includes the invite URL with the access token' do
      expect(mail.body.encoded).to include(contest_invite_url(token: contest_instance.access_token))
    end

    it 'includes the invitee email and contact email' do
      expect(mail.body.encoded).to include('invitee@umich.edu')
      expect(mail.body.encoded).to include('contest_admin@umich.edu')
    end

    it 'includes the submission window dates' do
      expect(mail.body.encoded).to include(I18n.l(contest_instance.date_open, format: :long))
      expect(mail.body.encoded).to include(I18n.l(contest_instance.date_closed, format: :long))
    end

    it 'falls back to default reply-to when container contact email is blank' do
      container.contact_email = ''
      container.save(validate: false)

      mail_without_contact = described_class.invite_to_submit(invitation)
      expect(mail_without_contact.reply_to).to eq([ 'lsa-evaluate-support@umich.edu' ])
    end

    it 'uses a plain email address in the mailto fallback when contact email is blank' do
      container.contact_email = ''
      container.save(validate: false)

      mail_without_contact = described_class.invite_to_submit(invitation)
      body = mail_without_contact.body.encoded

      expect(body).to include('mailto:lsa-evaluate-support@umich.edu')
      expect(body).not_to include('LSA Evaluate Support <')
      expect(body).not_to include('mailto:LSA Evaluate Support')
    end
  end
end
