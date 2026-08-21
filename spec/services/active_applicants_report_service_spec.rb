# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveApplicantsReportService do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }

  def create_active_entry!(last_name:, first_name:, **entry_attrs)
    user = create(:user, last_name: last_name, first_name: first_name)
    profile = create(:profile, user: user)
    create(:entry, { contest_instance: contest_instance, profile: profile }.merge(entry_attrs))
    profile
  end

  describe '#call' do
    it 'returns distinct active applicant profiles ordered by user last then first name' do
      zebra = create_active_entry!(last_name: 'Zebra', first_name: 'Ann')
      alpha = create_active_entry!(last_name: 'Alpha', first_name: 'Zoe')
      # Second active entry for the same profile must not duplicate the row.
      create(:entry, contest_instance: contest_instance, profile: alpha, title: 'Second Entry')

      results = described_class.new(
        container: container,
        contest_descriptions: [contest_description]
      ).call

      expect(results.map(&:id)).to eq([alpha.id, zebra.id])
      expect(results.map(&:last_name)).to eq(%w[Alpha Zebra])
      expect(results.map(&:first_name)).to eq(%w[Zoe Ann])
      expect(results.map { |profile| profile.user.email }).to eq([alpha.user.email, zebra.user.email])
    end

    it 'excludes deleted and disqualified entries' do
      keep = create_active_entry!(last_name: 'Keep', first_name: 'Yes')
      create_active_entry!(last_name: 'Gone', first_name: 'Deleted', deleted: true)
      create_active_entry!(last_name: 'Out', first_name: 'Disqualified', disqualified: true)

      results = described_class.new(
        container: container,
        contest_descriptions: [contest_description]
      ).call

      expect(results.map(&:id)).to eq([keep.id])
    end

    it 'excludes applicants whose contest description or instance is inactive' do
      create_active_entry!(last_name: 'Active', first_name: 'Applicant')

      inactive_description = create(:contest_description, :active, container: container)
      inactive_desc_instance = create(:contest_instance, contest_description: inactive_description, active: true)
      create(:entry, contest_instance: inactive_desc_instance, profile: create(:profile))
      inactive_desc_instance.update!(active: false)
      inactive_description.update!(active: false)

      inactive_instance = create(:contest_instance, contest_description: contest_description, active: false)
      create(:entry, contest_instance: inactive_instance, profile: create(:profile))

      results = described_class.new(
        container: container,
        contest_descriptions: ContestDescription.where(id: [contest_description.id, inactive_description.id])
      ).call

      expect(results.map { |profile| profile.user.last_name }).to eq(['Active'])
    end

    it 'only includes applicants for the requested contest descriptions' do
      included = create_active_entry!(last_name: 'Included', first_name: 'Person')

      other_description = create(:contest_description, :active, container: container)
      other_instance = create(:contest_instance, contest_description: other_description, active: true)
      create(:entry, contest_instance: other_instance, profile: create(:profile))

      results = described_class.new(
        container: container,
        contest_descriptions: [contest_description]
      ).call

      expect(results.map(&:id)).to eq([included.id])
    end
  end
end
