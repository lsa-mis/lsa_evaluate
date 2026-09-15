# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomFailure do
  subject(:failure_app) { described_class.new }

  before do
    # root_path needs request URL options; keep the failure app unit-testable.
    allow(failure_app).to receive(:root_path).and_return('/')
  end

  describe '#redirect_url' do
    it 'sends timed-out sessions to the root path' do
      allow(failure_app).to receive(:warden_message).and_return(:timeout)

      expect(failure_app.redirect_url).to eq('/')
    end

    it 'delegates to Devise for other failure reasons' do
      allow(failure_app).to receive(:warden_message).and_return(:unauthenticated)
      allow(failure_app).to receive(:scope_url).and_return('/users/sign_in')

      expect(failure_app.redirect_url).to eq('/users/sign_in')
    end
  end

  describe '#i18n_message' do
    it 'explains that the session expired on timeout' do
      allow(failure_app).to receive(:warden_message).and_return(:timeout)

      expect(failure_app.i18n_message).to eq(
        'Your session has expired. Please log in again to continue.'
      )
    end

    it 'delegates to Devise for other failure reasons' do
      allow(failure_app).to receive(:warden_message).and_return(:unauthenticated)
      allow(failure_app).to receive(:scope).and_return(:user)
      allow(failure_app).to receive(:scope_class).and_return(User)

      expect(failure_app.i18n_message).not_to include('session has expired')
      expect(failure_app.i18n_message).to be_present
    end
  end
end
