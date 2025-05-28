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

    describe '.active' do
      it 'includes active contests' do
        expect(ContestDescription.active).to include(active_contest)
      end
    end
  end

  describe 'deactivation with active instances' do
    let(:container) { create(:container) }
    let!(:description) { create(:contest_description, container: container, active: true) }
    let!(:active_instance) { create(:contest_instance, contest_description: description, active: true) }
    let!(:inactive_instance) { create(:contest_instance, contest_description: description, active: false) }

    it 'is not valid to deactivate if any contest_instance is active' do
      description.active = false
      expect(description).not_to be_valid
      expect(description.errors[:active]).to include('Cannot deactivate contest description while instances are active.')
    end

    it 'is valid to deactivate if all contest_instances are inactive' do
      active_instance.update!(active: false)
      description.active = false
      expect(description).to be_valid
    end

    it 'returns only active contest_instances from #active_contest_instances' do
      expect(description.active_contest_instances).to contain_exactly(active_instance)
    end
  end
end
