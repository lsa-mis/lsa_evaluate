# spec/controllers/entries_controller_spec.rb
require 'rails_helper'

RSpec.describe EntriesController, type: :controller do
  describe 'PATCH #soft_delete' do
    let(:user) { create(:user) }
    let(:profile) { create(:profile, user: user) }
    let(:contest_instance) { create(:contest_instance, date_open: date_open, date_closed: date_closed) }
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

    before do
      sign_in user
    end

    context 'when the contest instance is still open (date_closed in the future)' do
      let(:date_closed) { 1.day.from_now }
      let(:date_open) { 1.day.ago }

      it 'soft deletes the entry and redirects with a success notice' do
        patch :soft_delete, params: { id: entry.id }

        entry.reload
        expect(entry.deleted).to be true
        expect(response).to redirect_to(applicant_dashboard_path)
        expect(flash[:notice]).to eq('Entry was successfully removed.')
      end
    end

    context 'when the contest instance has closed (date_closed in the past)' do
      let(:date_closed) { 1.day.ago }
      let(:date_open) { 2.days.ago }

      it 'does not delete the entry and redirects with an alert' do
        patch :soft_delete, params: { id: entry.id }

        entry.reload
        expect(entry.deleted).to be false
        expect(response).to redirect_to(applicant_dashboard_path)
        expect(flash[:alert]).to eq('Cannot delete entry after contest has closed.')
      end
    end
  end
end
