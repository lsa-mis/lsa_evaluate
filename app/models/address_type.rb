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
class AddressType < ApplicationRecord
  has_many :addresses
  validates :kind, presence: true, uniqueness: true
end
