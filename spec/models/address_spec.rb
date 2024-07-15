# == Schema Information
#
# Table name: addresses
#
#  id              :bigint           not null, primary key
#  address1        :string(255)
#  address2        :string(255)
#  city            :string(255)
#  country         :integer
#  phone           :string(255)
#  state           :integer
#  zip             :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  address_type_id :bigint
#
# Indexes
#
#  id_unq_idx                          (id) UNIQUE
#  index_addresses_on_address_type_id  (address_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_type_id => address_types.id)
#

require 'rails_helper'

RSpec.describe Address do
  before do
    @address_type = AddressType.create(kind: 'Home')
  end

  it 'is valid with valid attributes' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).to be_valid
  end

  it 'is not valid without address1' do
    address = Address.new(
      address1: nil,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without city' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: nil,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without state' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: nil,
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without zip' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: nil,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without phone' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: nil,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without country' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: nil,
      address_type: @address_type
    )
    expect(address).not_to be_valid
  end

  it 'is not valid without address_type' do
    address = Address.new(
      address1: Faker::Address.street_address,
      address2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Number.between(from: 1, to: 50),
      zip: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      country: Faker::Number.between(from: 1, to: 250),
      address_type: nil
    )
    expect(address).not_to be_valid
  end
end
