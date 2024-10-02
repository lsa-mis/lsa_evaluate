# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
#  id              :bigint           not null, primary key
#  address1        :string(255)
#  address2        :string(255)
#  city            :string(255)
#  country         :string(255)
#  state           :string(255)
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
  has_many :home_profiles, class_name: 'Profile', foreign_key: 'home_address_id', dependent: :restrict_with_exception
  has_many :campus_profiles, class_name: 'Profile', foreign_key: 'campus_address_id', dependent: :restrict_with_exception

  validates :address1, :city, :state, :zip, :country, presence: true

  STATES =
    [
      [ 'Alabama', 'AL' ],
      [ 'Alaska', 'AK' ],
      [ 'Arizona', 'AZ' ],
      [ 'Arkansas', 'AR' ],
      [ 'California', 'CA' ],
      [ 'Colorado', 'CO' ],
      [ 'Connecticut', 'CT' ],
      [ 'Delaware', 'DE' ],
      [ 'District of Columbia', 'DC' ],
      [ 'Florida', 'FL' ],
      [ 'Georgia', 'GA' ],
      [ 'Hawaii', 'HI' ],
      [ 'Idaho', 'ID' ],
      [ 'Illinois', 'IL' ],
      [ 'Indiana', 'IN' ],
      [ 'Iowa', 'IA' ],
      [ 'Kansas', 'KS' ],
      [ 'Kentucky', 'KY' ],
      [ 'Louisiana', 'LA' ],
      [ 'Maine', 'ME' ],
      [ 'Maryland', 'MD' ],
      [ 'Massachusetts', 'MA' ],
      [ 'Michigan', 'MI' ],
      [ 'Minnesota', 'MN' ],
      [ 'Mississippi', 'MS' ],
      [ 'Missouri', 'MO' ],
      [ 'Montana', 'MT' ],
      [ 'Nebraska', 'NE' ],
      [ 'Nevada', 'NV' ],
      [ 'New Hampshire', 'NH' ],
      [ 'New Jersey', 'NJ' ],
      [ 'New Mexico', 'NM' ],
      [ 'New York', 'NY' ],
      [ 'North Carolina', 'NC' ],
      [ 'North Dakota', 'ND' ],
      [ 'Ohio', 'OH' ],
      [ 'Oklahoma', 'OK' ],
      [ 'Oregon', 'OR' ],
      [ 'Pennsylvania', 'PA' ],
      [ 'Puerto Rico', 'PR' ],
      [ 'Rhode Island', 'RI' ],
      [ 'South Carolina', 'SC' ],
      [ 'South Dakota', 'SD' ],
      [ 'Tennessee', 'TN' ],
      [ 'Texas', 'TX' ],
      [ 'Utah', 'UT' ],
      [ 'Vermont', 'VT' ],
      [ 'Virginia', 'VA' ],
      [ 'Washington', 'WA' ],
      [ 'West Virginia', 'WV' ],
      [ 'Wisconsin', 'WI' ],
      [ 'Wyoming', 'WY' ]
    ].freeze

  # def full_address
  #   "#{address1} #{address2} #{city}, #{state} #{zip}"
  # end
  def full_address
    "#{address1}\n#{address2.present? ? "#{address2}\n" : ''}#{city}, #{state} #{zip}\n#{country_abbreviation}"
  end

  def country_name
    country_data = ISO3166::Country[country]
    country_data.translations[I18n.locale.to_s] || country_data.name if country_data
  end

  def country_abbreviation
    country_data = ISO3166::Country[country]
    country_data.alpha2 if country_data
  end
end
