require 'rails_helper'

RSpec.describe Campus, type: :model do
  subject(:campus) { build(:campus) }

  context 'validations' do
    it 'is valid with valid attributes' do
      expect(campus).to be_valid
    end

    it 'is not valid without a campus_descr' do
      campus.campus_descr = nil
      expect(campus).not_to be_valid
      expect(campus.errors[:campus_descr]).to include("can't be blank")
    end

    it 'is not valid without a campus_cd' do
      campus.campus_cd = nil
      expect(campus).not_to be_valid
      expect(campus.errors[:campus_cd]).to include("can't be blank")
    end

    it 'is not valid with a duplicate campus_descr' do
      create(:campus, campus_descr: campus.campus_descr)
      expect(campus).not_to be_valid
      expect(campus.errors[:campus_descr]).to include('has already been taken')
    end

    it 'is not valid with a duplicate campus_cd' do
      create(:campus, campus_cd: campus.campus_cd)
      expect(campus).not_to be_valid
      expect(campus.errors[:campus_cd]).to include('has already been taken')
    end
  end

  context 'attributes' do
    it 'has a campus_descr' do
      campus.campus_descr = 'Main Campus'
      expect(campus.campus_descr).to eq('Main Campus')
    end

    it 'has a campus_cd' do
      campus.campus_cd = 1234
      expect(campus.campus_cd).to eq(1234)
    end
  end
end
