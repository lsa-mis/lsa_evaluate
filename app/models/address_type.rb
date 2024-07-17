# == Schema Information
#
# Table name: address_types
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  id_unq_idx                   (id) UNIQUE
#  index_address_types_on_kind  (kind) UNIQUE
#
class AddressType < ApplicationRecord
  has_many :addresses
  validates :kind, presence: true, uniqueness: true
end
