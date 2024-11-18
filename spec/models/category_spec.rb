# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  kind        :string(255)
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Category, type: :model do
  let(:category) { create(:category, :drama) }

  describe 'Factory' do
    it 'creates a valid entry' do
      category = create(:category) # Using the factory directly
      expect(category).to be_valid
    end
  end

  describe 'associations' do
    it 'has many contest_instances through category_contest_instances' do
      association = described_class.reflect_on_association(:contest_instances)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:category_contest_instances)
    end

    it 'has many category_contest_instances' do
      association = described_class.reflect_on_association(:category_contest_instances)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of kind' do
      # Create a category with a unique kind
      create(:category, :drama)

      # Attempt to create another category with the same kind
      duplicate_category = build(:category, :drama)

      expect(duplicate_category).not_to be_valid
      expect(duplicate_category.errors[:kind]).to include('has already been taken')
    end

    it 'validates presence of kind' do
      category = build(:category, :drama, kind: nil)
      expect(category).not_to be_valid
      expect(category.errors[:kind]).to include("can't be blank")
    end

    it 'validates presence of description' do
      category = build(:category, :drama, description: nil)
      expect(category).not_to be_valid
      expect(category.errors[:description]).to include("can't be blank")
    end
  end
end
