# == Schema Information
#
# Table name: address_types
#
#  id          :bigint           not null, primary key
#  kind        :string(255)      not null
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe AddressType, type: :model do
  before do
    described_class.delete_all
  end

  it 'is valid with valid attributes' do
    expect(build(:address_type)).to be_valid
  end

  it 'is not valid without a kind' do
    expect(build(:address_type, kind: nil)).not_to be_valid
  end

  it 'is not valid with a duplicate kind' do
    create(:address_type, kind: 'Home')
    expect(build(:address_type, kind: 'Home')).not_to be_valid
  end
end
