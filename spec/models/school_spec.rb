# == Schema Information
#
# Table name: schools
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  id_unq_idx  (id) UNIQUE
#
require 'rails_helper'

RSpec.describe School, type: :model do
  subject(:school) { build(:school) }

  context 'validations' do
    it 'is valid with valid attributes' do
      expect(school).to be_valid
    end

    it 'is not valid without a name' do
      school.name = nil
      expect(school).not_to be_valid
      expect(school.errors[:name]).to include("can't be blank")
    end

    it 'is not valid with a duplicate id' do
      create(:school, id: 1)
      duplicate_school = build(:school, id: 1)
      expect(duplicate_school).not_to be_valid
    end
  end
end
