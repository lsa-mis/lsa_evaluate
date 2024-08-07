# == Schema Information
#
# Table name: contest_descriptions
#
#  id                :bigint           not null, primary key
#  created_by        :string(255)      not null
#  eligibility_rules :text(65535)
#  name              :string(255)      not null
#  notes             :text(65535)
#  short_name        :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  container_id      :bigint           not null
#  status_id         :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#  index_contest_descriptions_on_status_id     (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#  fk_rails_...  (status_id => statuses.id)
#
require 'rails_helper'

RSpec.describe ContestDescription, type: :model do
  subject(:contest_description) { build(:contest_description) }

  context 'associations' do
    it 'belongs to a container' do
      association = described_class.reflect_on_association(:container)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a status' do
      association = described_class.reflect_on_association(:status)
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

  context 'attributes' do
    it 'has a name' do
      contest_description.name = 'Test Contest'
      expect(contest_description.name).to eq('Test Contest')
    end

    it 'has a created_by' do
      contest_description.created_by = 'John Doe'
      expect(contest_description.created_by).to eq('John Doe')
    end

    it 'has eligibility_rules' do
      contest_description.eligibility_rules = 'Must be a student'
      expect(contest_description.eligibility_rules).to eq('Must be a student')
    end

    it 'has notes' do
      contest_description.notes = 'Some important notes'
      expect(contest_description.notes).to eq('Some important notes')
    end

    it 'has a short_name' do
      contest_description.short_name = 'Test'
      expect(contest_description.short_name).to eq('Test')
    end
  end
end
