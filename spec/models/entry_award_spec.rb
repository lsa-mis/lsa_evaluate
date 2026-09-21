# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAward, type: :model do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:primary_award) { create(:award, container: container, name: 'First Place', default_amount: 1500, default_shortcode: 'SC-100') }
  let(:add_on_award) { create(:award, :add_on, container: container, name: 'Book Prize', default_amount: 50, default_shortcode: 'SC-200') }

  describe 'factory' do
    it 'creates a valid assignment' do
      expect(build(:entry_award, entry: entry, award: primary_award)).to be_valid
    end
  end

  describe 'snapshots' do
    it 'copies amount and shortcode from the catalog on create' do
      entry_award = create(:entry_award, entry: entry, award: primary_award)

      expect(entry_award.amount).to eq(1500)
      expect(entry_award.shortcode).to eq('SC-100')
    end

    it 'keeps explicit amount and shortcode overrides' do
      entry_award = create(
        :entry_award,
        entry: entry,
        award: primary_award,
        amount: 1750,
        shortcode: 'SC-OVERRIDE'
      )

      expect(entry_award.amount).to eq(1750)
      expect(entry_award.shortcode).to eq('SC-OVERRIDE')
    end

    it 'does not change historical snapshots when the catalog is updated' do
      entry_award = create(:entry_award, entry: entry, award: primary_award)
      primary_award.update!(default_amount: 2000, default_shortcode: 'SC-NEW')

      expect(entry_award.reload.amount).to eq(1500)
      expect(entry_award.shortcode).to eq('SC-100')
    end
  end

  describe 'one primary prize' do
    it 'allows one primary prize and many add-ons' do
      create(:entry_award, entry: entry, award: primary_award)
      expect(build(:entry_award, entry: entry, award: add_on_award)).to be_valid
    end

    it 'rejects a second primary prize on the same entry' do
      create(:entry_award, entry: entry, award: primary_award)
      second_primary = create(:award, container: container, name: 'Grand Prize')
      duplicate = build(:entry_award, entry: entry, award: second_primary)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:award]).to include('already has a primary prize assigned')
    end
  end

  describe 'collection scoping' do
    it 'rejects an award from another collection' do
      other_award = create(:award)
      entry_award = build(:entry_award, entry: entry, award: other_award)

      expect(entry_award).not_to be_valid
      expect(entry_award.errors[:award]).to include('must belong to the same collection as this entry')
    end

    it 'rejects an inactive catalog award on create' do
      inactive = create(:award, :inactive, container: container, name: 'Retired Prize')
      entry_award = build(:entry_award, entry: entry, award: inactive)

      expect(entry_award).not_to be_valid
      expect(entry_award.errors[:award]).to include('is not active in the collection catalog')
    end
  end
end
