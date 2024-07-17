# == Schema Information
#
# Table name: class_levels
#
#  id          :bigint           not null, primary key
#  description :text(65535)      not null
#  name        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe ClassLevel do
  let(:class_level) { build(:class_level) }

  describe 'validations' do
    it 'validates presence of name' do
      class_level.name = nil
      expect(class_level).not_to be_valid
      expect(class_level.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:class_level, name: 'UniqueName')
      class_level.name = 'UniqueName'
      expect(class_level).not_to be_valid
      expect(class_level.errors[:name]).to include('has already been taken')
    end

    it 'validates presence of description' do
      class_level.description = nil
      expect(class_level).not_to be_valid
      expect(class_level.errors[:description]).to include("can't be blank")
    end
  end

  describe 'Factory' do
    it 'is valid with valid attributes' do
      expect(class_level).to be_valid
    end
  end
end
