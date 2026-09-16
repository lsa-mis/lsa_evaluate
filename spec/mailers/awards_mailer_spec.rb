# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwardsMailer, type: :mailer do
  let(:user) { create(:user, email: 'winner@example.com', first_name: 'Ada', last_name: 'Lovelace') }
  let(:profile) { create(:profile, user: user) }
  let(:container) { create(:container, contact_email: 'awards@example.com') }
  let(:contest_description) { create(:contest_description, :active, name: 'Poetry Contest', container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) do
    create(
      :entry,
      title: 'Ode to Code',
      profile: profile,
      contest_instance: contest_instance,
      award_status: 'winner',
      placement: 1
    )
  end
  let!(:entry_award) { create(:entry_award, entry: entry, amount: 1000, shortcode: 'SECRET-SC') }

  describe '#award_notice' do
    let(:mail) { described_class.award_notice(entry.reload, include_amounts: true) }

    it 'sends to the applicant with contest details' do
      expect(mail.to).to eq([ 'winner@example.com' ])
      expect(mail.subject).to include('Ode to Code')
      expect(mail.subject).to include('Poetry Contest')
      expect(mail.reply_to).to eq([ 'awards@example.com' ])
    end

    it 'includes placement and prize names but never shortcodes' do
      expect(mail.body.encoded).to include('Winner')
      expect(mail.body.encoded).to include('1st')
      expect(mail.body.encoded).to include(entry_award.award.name)
      expect(mail.body.encoded).to include('$1,000')
      expect(mail.body.encoded).not_to include('SECRET-SC')
    end

    it 'omits amounts when the option is off' do
      mail_without_amounts = described_class.award_notice(entry.reload, include_amounts: false)

      expect(mail_without_amounts.body.encoded).to include(entry_award.award.name)
      expect(mail_without_amounts.body.encoded).not_to include('$1,000')
      expect(mail_without_amounts.body.encoded).not_to include('SECRET-SC')
    end
  end
end
