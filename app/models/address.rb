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

class Address < ApplicationRecord
  belongs_to :address_type

  validates :address1, :city, :state, :zip, :phone, :country, presence: true
end
