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
#  address_type_id_idx                 (address_type_id)
#  id_unq_idx                          (id) UNIQUE
#  index_addresses_on_address_type_id  (address_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_type_id => address_types.id)
#

FactoryBot.define do
  factory :address do
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip_code }
    phone { Faker::PhoneNumber.phone_number }
    country { Faker::Address.country_code }
    association :address_type
  end
end
