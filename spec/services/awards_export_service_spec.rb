# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwardsExportService do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Drama Award') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance, award_status: 'winner', placement: 1, title: 'Winning Play') }
  let!(:primary) { create(:entry_award, entry: entry, amount: 1500, shortcode: 'SC-PRIMARY') }
  let!(:add_on) { create(:entry_award, :add_on, entry: entry, amount: 200, shortcode: 'SC-ADDON') }

  subject(:service) do
    described_class.new(
      entries: contest_instance.entries.active,
      title: 'Drama Award - Award roster',
      contest_instance: contest_instance
    )
  end

  describe '#roster_csv' do
    it 'includes one row per awarded entry with prizes and student data' do
      csv = service.roster_csv

      expect(csv).to include('Drama Award - Award roster')
      expect(csv).to include('Winning Play')
      expect(csv).to include(entry.profile.umid)
      expect(csv).to include('Winner')
      expect(csv).to include('1st')
      expect(csv).to include('1500.00')
      expect(csv).to include('SC-PRIMARY')
      expect(csv).to include('SC-ADDON')
      expect(csv).to include('1700.00')
    end
  end

  describe '#disbursement_csv' do
    it 'includes one row per assigned prize' do
      csv = service.disbursement_csv
      lines = csv.split("\n").reject(&:blank?)

      expect(csv).to include('Prize Name')
      expect(csv).to include('SC-PRIMARY')
      expect(csv).to include('SC-ADDON')
      expect(lines.grep(/Winning Play/).size).to eq(2)
    end
  end
end
