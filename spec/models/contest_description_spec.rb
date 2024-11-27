# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#  created_by   :string(255)      not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
require 'rails_helper'

RSpec.describe ContestDescription, type: :model do
  subject(:contest_description) { build(:contest_description) }

  context 'associations' do
    it 'belongs to a container' do
      association = described_class.reflect_on_association(:container)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many contest_instances' do
      association = described_class.reflect_on_association(:contest_instances)
      expect(association.macro).to eq :has_many
    end
  end

  context 'validations' do
    it 'is valid with valid attributes' do
      expect(contest_description).to be_valid
    end

    it 'is not valid without a name' do
      contest_description.name = nil
      expect(contest_description).not_to be_valid
      expect(contest_description.errors[:name]).to include("can't be blank")
    end

    it 'is not valid without created_by' do
      contest_description.created_by = nil
      expect(contest_description).not_to be_valid
      expect(contest_description.errors[:created_by]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    let!(:active_contest) { create(:contest_description, active: true) }
    let!(:archived_contest) { create(:contest_description, archived: true) }

    describe '.active' do
      it 'includes active contests' do
        expect(ContestDescription.active).to include(active_contest)
      end

      it 'excludes non-active contests' do
        expect(ContestDescription.active).not_to include(archived_contest)
      end
    end

    describe '.archived' do
      it 'includes archived contests' do
        expect(ContestDescription.archived).to include(archived_contest)
      end

      it 'excludes non-archived contests' do
        expect(ContestDescription.archived).not_to include(active_contest)
      end
    end
  end
end
