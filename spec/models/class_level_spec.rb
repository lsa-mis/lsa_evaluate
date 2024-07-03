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
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe 'Factory' do
    it 'is valid with valid attributes' do
      class_level = FactoryBot.build(:class_level)
      expect(class_level).to be_valid
    end
  end
end
