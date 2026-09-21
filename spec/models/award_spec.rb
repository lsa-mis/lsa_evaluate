# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Award, type: :model do
  let(:container) { create(:container) }

  describe 'factory' do
    it 'creates a valid award' do
      expect(build(:award, container: container)).to be_valid
    end
  end

  describe 'validations' do
    it 'requires a name' do
      award = build(:award, container: container, name: nil)
      expect(award).not_to be_valid
      expect(award.errors[:name]).to include("can't be blank")
    end

    it 'requires a unique name within a collection' do
      create(:award, container: container, name: 'First Place')
      duplicate = build(:award, container: container, name: 'first place')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'allows the same name in another collection' do
      create(:award, container: container, name: 'First Place')
      other = build(:award, name: 'First Place')

      expect(other).to be_valid
    end

    it 'rejects a negative default amount' do
      award = build(:award, container: container, default_amount: -1)
      expect(award).not_to be_valid
    end

    it 'allows a blank default amount' do
      award = build(:award, container: container, default_amount: nil)
      expect(award).to be_valid
    end

    it 'rejects an invalid kind without raising' do
      award = build(:award, container: container)
      award.kind = 'not_a_real_kind'

      expect(award).not_to be_valid
      expect(award.errors[:kind]).to include('is not included in the list')
    end
  end

  describe 'position' do
    it 'assigns the next position when created' do
      first = create(:award, container: container, name: 'First Place')
      second = create(:award, container: container, name: 'Second Place')

      expect(first.position).to eq(0)
      expect(second.position).to eq(1)
    end
  end

  describe '#kind_label' do
    it 'returns a human label for add-on prizes' do
      award = build(:award, :add_on, container: container)
      expect(award.kind_label).to eq('Add-on prize')
    end
  end

  describe 'kind' do
    it 'allows kind to change before the prize is assigned' do
      award = create(:award, :add_on, container: container)

      expect(award.update(kind: 'primary')).to be true
    end

    it 'does not allow kind to change after the prize is assigned' do
      award = create(:award, :add_on, container: container)
      contest_description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: contest_description)
      entry = create(:entry, contest_instance: contest_instance)
      create(:entry_award, entry: entry, award: award)

      award.reload
      award.kind = 'primary'

      expect(award).not_to be_valid
      expect(award.errors[:kind]).to include('cannot be changed after the prize has been assigned')
    end
  end

  describe 'destroy' do
    it 'is blocked when the award has been assigned' do
      award = create(:award, container: container)
      contest_description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: contest_description)
      entry = create(:entry, contest_instance: contest_instance)
      create(:entry_award, entry: entry, award: award)

      expect(award.destroy).to be false
      expect(award.errors[:base]).to be_present
    end
  end
end
