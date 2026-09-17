# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContainerWinnersQuery do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Poetry') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let!(:winner) do
    create(:entry, contest_instance: contest_instance, award_status: 'winner', placement: 1, title: 'Winner Poem')
  end
  let!(:finalist) do
    create(:entry, contest_instance: contest_instance, award_status: 'finalist', placement: 2, title: 'Finalist Poem')
  end
  let!(:unawarded) do
    create(:entry, contest_instance: contest_instance, award_status: 'unawarded', title: 'Unawarded Poem')
  end

  before do
    create(:entry_award, entry: winner)
    create(:entry_award, :add_on, entry: finalist)
  end

  def entry_ids(**filters)
    described_class.new(container: container, **filters).entries.map(&:id)
  end

  it 'returns awarded entries for the collection and excludes unawarded ones' do
    ids = entry_ids

    expect(ids).to include(winner.id, finalist.id)
    expect(ids).not_to include(unawarded.id)
  end

  it 'excludes awarded entries from other collections' do
    other_description = create(:contest_description, :active, name: 'Other')
    other_instance = create(:contest_instance, contest_description: other_description)
    other_entry = create(:entry, contest_instance: other_instance, award_status: 'winner', title: 'Other Winner')
    create(:entry_award, entry: other_entry)

    expect(entry_ids).not_to include(other_entry.id)
  end

  it 'filters by contest description' do
    sibling_description = create(:contest_description, :active, container: container, name: 'Fiction')
    sibling_instance = create(:contest_instance, contest_description: sibling_description, active: false)
    sibling_entry = create(:entry, contest_instance: sibling_instance, award_status: 'winner', title: 'Fiction Winner')
    create(:entry_award, entry: sibling_entry)

    ids = entry_ids(contest_description_id: contest_description.id)

    expect(ids).to include(winner.id)
    expect(ids).not_to include(sibling_entry.id)
  end

  it 'filters by contest instance' do
    sibling_instance = create(
      :contest_instance,
      contest_description: contest_description,
      active: false,
      date_open: contest_instance.date_open - 1.year,
      date_closed: contest_instance.date_closed - 1.year
    )
    older_entry = create(:entry, contest_instance: sibling_instance, award_status: 'winner', title: 'Older Winner')
    create(:entry_award, entry: older_entry)

    ids = entry_ids(contest_instance_id: contest_instance.id)

    expect(ids).to include(winner.id)
    expect(ids).not_to include(older_entry.id)
  end

  it 'filters by award status' do
    ids = entry_ids(award_status: 'finalist')

    expect(ids).to contain_exactly(finalist.id)
  end

  it 'filters by award kind' do
    ids = entry_ids(award_kind: 'add_on')

    expect(ids).to contain_exactly(finalist.id)
  end

  it 'ignores an invalid award kind filter instead of raising' do
    ids = entry_ids(award_kind: 'not_a_real_kind')

    expect(ids).to include(winner.id, finalist.id)
  end

  it 'includes entries that are still marked unawarded but have a prize assigned' do
    prize_only = create(
      :entry,
      contest_instance: contest_instance,
      award_status: 'unawarded',
      title: 'Prize Without Status'
    )
    create(:entry_award, entry: prize_only)

    expect(entry_ids).to include(prize_only.id)
  end
end
