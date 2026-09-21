# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwardsHelper, type: :helper do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }

  describe '#award_status_options' do
    it 'lists the workspace outcome statuses' do
      expect(helper.award_status_options).to eq(
        [
          [ 'Unawarded', 'unawarded' ],
          [ 'Winner', 'winner' ],
          [ 'Finalist', 'finalist' ]
        ]
      )
    end
  end

  describe '#placement_options' do
    it 'includes a blank option followed by 1st through 10th' do
      expect(helper.placement_options.first).to eq([ '—', '' ])
      expect(helper.placement_options[1]).to eq([ '1st', 1 ])
      expect(helper.placement_options.last).to eq([ '10th', 10 ])
      expect(helper.placement_options.size).to eq(11)
    end
  end

  describe '#format_award_amount' do
    it 'returns an em dash when the amount is blank' do
      expect(helper.format_award_amount(nil)).to eq('—')
      expect(helper.format_award_amount('')).to eq('—')
    end

    it 'formats numeric amounts as currency' do
      expect(helper.format_award_amount(1500)).to eq('$1,500.00')
    end
  end

  describe '#assignable_catalog_awards' do
    let!(:primary_one) { create(:award, container: container, name: 'First Place') }
    let!(:primary_two) { create(:award, container: container, name: 'Grand Prize') }
    let!(:add_on) { create(:award, :add_on, container: container, name: 'Book Prize') }
    let(:catalog) { [ primary_one, primary_two, add_on ] }

    it 'returns the full catalog when nothing is assigned' do
      expect(helper.assignable_catalog_awards(entry, catalog)).to match_array(catalog)
    end

    it 'excludes awards already assigned to the entry' do
      create(:entry_award, entry: entry, award: add_on)

      expect(helper.assignable_catalog_awards(entry.reload, catalog)).to contain_exactly(primary_one, primary_two)
    end

    it 'hides remaining primary prizes once a primary is assigned' do
      create(:entry_award, entry: entry, award: primary_one)

      expect(helper.assignable_catalog_awards(entry.reload, catalog)).to contain_exactly(add_on)
    end
  end

  describe '#suggested_for_award?' do
    it 'is true when the entry was selected in the last judging round' do
      allow(contest_instance).to receive(:last_round_selected_entry_ids).and_return(Set.new([ entry.id ]))

      expect(helper.suggested_for_award?(entry, contest_instance)).to be true
    end

    it 'is false when the entry was not selected in the last judging round' do
      allow(contest_instance).to receive(:last_round_selected_entry_ids).and_return(Set.new([ entry.id + 1 ]))

      expect(helper.suggested_for_award?(entry, contest_instance)).to be false
    end
  end

  describe '#entry_prizes_summary' do
    it 'returns an em dash when no prizes are assigned' do
      expect(helper.entry_prizes_summary(entry)).to eq('—')
    end

    it 'joins assigned prize names' do
      primary = create(:award, container: container, name: 'First Place')
      add_on = create(:award, :add_on, container: container, name: 'Book Prize')
      create(:entry_award, entry: entry, award: primary)
      create(:entry_award, entry: entry, award: add_on)

      expect(helper.entry_prizes_summary(entry.reload)).to eq('First Place, Book Prize')
    end
  end
end
