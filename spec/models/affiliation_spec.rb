# spec/models/affiliation_spec.rb

require 'rails_helper'

RSpec.describe Affiliation, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      affiliation = build(:affiliation, user: user)
      expect(affiliation).to be_valid
    end

    it 'is not valid without a name' do
      affiliation = build(:affiliation, name: nil, user: user)
      expect(affiliation).not_to be_valid
    end

    it 'is not valid without a user' do
      affiliation = build(:affiliation, user: nil)
      expect(affiliation).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'database structure' do
    it 'has a name column' do
      expect(Affiliation.column_names).to include('name')
    end

    it 'has a user_id column' do
      expect(Affiliation.column_names).to include('user_id')
    end
  end
end
