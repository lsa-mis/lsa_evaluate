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

RSpec.describe Category do
  let(:category) { build(:category) }

  it 'validates presence of kind' do
    category.kind = nil
    expect(category).not_to be_valid
    expect(category).not_to be_valid
  end

  it 'validates uniqueness of kind' do
    create(:category, kind: 'Drama')
    category.kind = 'Drama'
    expect(category).not_to be_valid
    expect(category.errors[:kind]).to include('has already been taken')
  end

  it 'validates presence of description' do
    category.description = nil
    expect(category).not_to be_valid
    expect(category).not_to be_valid
  end
end
