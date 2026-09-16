# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAwardsController, type: :controller do
  let(:container) { create(:container) }
  let(:admin_user) { create(:user) }
  let(:admin_role) { create(:role, kind: 'Collection Administrator') }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:award) { create(:award, container: container, name: 'First Place', default_amount: 1000, default_shortcode: 'SC-1') }

  before do
    create(:assignment, user: admin_user, container: container, role: admin_role)
    sign_in admin_user
  end

  describe 'POST #create' do
    it 'assigns a catalog prize to an entry' do
      expect {
        post :create, params: nested_params.merge(
          entry_id: entry.id,
          entry_award: { award_id: award.id }
        )
      }.to change(EntryAward, :count).by(1)

      entry_award = entry.entry_awards.last
      expect(entry_award.amount).to eq(1000)
      expect(entry_award.shortcode).to eq('SC-1')
    end
  end

  describe 'PATCH #update' do
    it 'updates the snapshot amount and shortcode' do
      entry_award = create(:entry_award, entry: entry, award: award)

      patch :update, params: nested_params.merge(
        id: entry_award.id,
        entry_award: { amount: 1200, shortcode: 'SC-NEW' }
      )

      expect(entry_award.reload.amount).to eq(1200)
      expect(entry_award.shortcode).to eq('SC-NEW')
    end
  end

  describe 'DELETE #destroy' do
    it 'removes the assigned prize' do
      entry_award = create(:entry_award, entry: entry, award: award)

      expect {
        delete :destroy, params: nested_params.merge(id: entry_award.id)
      }.to change(EntryAward, :count).by(-1)
    end
  end

  def nested_params
    {
      container_id: container.id,
      contest_description_id: contest_description.id,
      contest_instance_id: contest_instance.id
    }
  end
end
