# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_categories_on_kind  (kind) UNIQUE
#
require 'rails_helper'

RSpec.describe Category, type: :model do
  let(:category) { create(:category_drama) }

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
      create(:category_drama)

      # Attempt to create another category with the same kind
      duplicate_category = build(:category_drama)

      expect(duplicate_category).not_to be_valid
      expect(duplicate_category.errors[:kind]).to include('has already been taken')
    end

    it 'validates presence of kind' do
      category = build(:category_drama, kind: nil)
      expect(category).not_to be_valid
      expect(category.errors[:kind]).to include("can't be blank")
    end

    it 'validates presence of description' do
      category = build(:category_drama, description: nil)
      expect(category).not_to be_valid
      expect(category.errors[:description]).to include("can't be blank")
    end
  end
end
