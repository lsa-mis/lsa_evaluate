# == Schema Information
#
# Table name: entries
#
#  id                  :bigint           not null, primary key
#  deleted             :boolean          default(FALSE), not null
#  disqualified        :boolean          default(FALSE), not null
#  title               :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  profile_id          :bigint           not null
#
# Indexes
#
#  category_id_idx                       (category_id)
#  contest_instance_id_idx               (contest_instance_id)
#  id_unq_idx                            (id) UNIQUE
#  index_entries_on_category_id          (category_id)
#  index_entries_on_contest_instance_id  (contest_instance_id)
#  index_entries_on_profile_id           (profile_id)
#  profile_id_idx                        (profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (profile_id => profiles.id)
#

require 'rails_helper'

RSpec.describe Entry, type: :model do
  let(:category) { create(:category, kind: "ecat") }
  let(:contest_instance) { create(:contest_instance) }
  let(:profile) { create(:profile) }

  describe 'Factory' do
    it 'creates a valid entry' do
      entry = create(:entry)
      expect(entry).to be_valid
    end

    it 'creates a valid entry with file attachment' do
      entry = create(:entry)
      expect(entry.entry_file).to be_attached
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      entry = build(:entry, category: category, contest_instance: contest_instance, profile: profile)
      expect(entry).to be_valid
    end

    it 'is not valid without a title' do
      entry = build(:entry, title: nil, category: category, contest_instance: contest_instance, profile: profile)
      expect(entry).not_to be_valid
    end

    it 'is not valid without a category' do
      entry = build(:entry, category: nil, contest_instance: contest_instance, profile: profile)
      expect(entry).not_to be_valid
    end

    it 'is not valid without a contest_instance' do
      entry = build(:entry, contest_instance: nil, category: category, profile: profile)
      expect(entry).not_to be_valid
    end

    it 'is not valid without a profile' do
      entry = build(:entry, profile: nil, category: category, contest_instance: contest_instance)
      expect(entry).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a category' do
      association = described_class.reflect_on_association(:category)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a contest_instance' do
      association = described_class.reflect_on_association(:contest_instance)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a profile' do
      association = described_class.reflect_on_association(:profile)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'database structure' do
    it 'has a title column' do
      expect(described_class.column_names).to include('title')
    end

    it 'has a category_id column' do
      expect(described_class.column_names).to include('category_id')
    end

    it 'has a contest_instance_id column' do
      expect(described_class.column_names).to include('contest_instance_id')
    end

    it 'has a profile_id column' do
      expect(described_class.column_names).to include('profile_id')
    end
  end
end
