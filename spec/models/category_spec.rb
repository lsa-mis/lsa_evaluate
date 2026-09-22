# == Schema Information
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  description  :text(65535)
#  kind         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_categories_on_container_id           (container_id)
#  index_categories_on_container_id_and_kind  (container_id,kind) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
require 'rails_helper'

RSpec.describe Category, type: :model do
  let(:container) { create(:container) }
  let(:category) { create(:category, :drama, container: container) }

  describe 'Factory' do
    it 'creates a valid entry' do
      category = create(:category)
      expect(category).to be_valid
      expect(category.container).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to a container' do
      association = described_class.reflect_on_association(:container)
      expect(association.macro).to eq(:belongs_to)
    end

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
    it 'validates uniqueness of kind within a container' do
      create(:category, :drama, container: container)

      duplicate_category = build(:category, :drama, container: container)
      expect(duplicate_category).not_to be_valid
      expect(duplicate_category.errors[:kind]).to include('has already been taken')
    end

    it 'allows the same kind on different containers' do
      other_container = create(:container)
      create(:category, :drama, container: container)

      expect(build(:category, :drama, container: other_container)).to be_valid
    end

    it 'validates presence of kind' do
      category = build(:category, :drama, kind: nil, container: container)
      expect(category).not_to be_valid
      expect(category.errors[:kind]).to include("can't be blank")
    end

    it 'validates presence of description' do
      category = build(:category, :drama, description: nil, container: container)
      expect(category).not_to be_valid
      expect(category.errors[:description]).to include("can't be blank")
    end
  end

  describe 'destroy restrictions' do
    it 'prevents deleting a category that still has entries' do
      contest_description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: contest_description)
      contest_instance.categories = [ category ]
      create(:entry, contest_instance: contest_instance, category: category)

      expect(category.destroy).to be false
      expect(category.errors[:base]).to be_present
      expect(Category.exists?(category.id)).to be true
    end
  end
end

