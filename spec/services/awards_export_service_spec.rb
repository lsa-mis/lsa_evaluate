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

    it 'sanitizes spreadsheet formulas in the title and question labels' do
      question = instance_double(ApplicationQuestion, id: -1, label: '=CMD()')
      dangerous = described_class.new(
        entries: contest_instance.entries.active,
        title: '=1+2',
        contest_instance: contest_instance
      )
      allow(dangerous).to receive(:application_questions).and_return([ question ])

      csv = dangerous.roster_csv

      expect(csv).to include("'=1+2")
      expect(csv).to include("'=CMD()")
      expect(csv).not_to match(/(^|,)=1\+2/)
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

    it 'sanitizes spreadsheet formulas in the title' do
      csv = described_class.new(
        entries: contest_instance.entries.active,
        title: '@SUM(A1)',
        contest_instance: contest_instance
      ).disbursement_csv

      expect(csv).to include("'@SUM(A1)")
    end
  end
end
