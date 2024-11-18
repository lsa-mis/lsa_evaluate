# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  user_id                       :bigint           not null
#  preferred_first_name          :string(255)      default(""), not null
#  preferred_last_name           :string(255)      default(""), not null
#  class_level_id                :bigint
#  school_id                     :bigint
#  campus_id                     :bigint
#  major                         :string(255)
#  grad_date                     :date             not null
#  degree                        :string(255)      not null
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  financial_aid_description     :text(65535)
#  hometown_publication          :string(255)
#  pen_name                      :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  home_address_id               :bigint
#  campus_address_id             :bigint
#  campus_employee               :boolean          default(FALSE), not null
#  department                    :string(255)
#  umid                          :string(255)
#
class Profile < ApplicationRecord
  before_save :normalize_names

  belongs_to :user
  belongs_to :class_level, optional: true
  belongs_to :school, optional: true
  belongs_to :campus, optional: true
  has_many :entries, dependent: :restrict_with_error

  belongs_to :home_address, class_name: 'Address', optional: true
  belongs_to :campus_address, class_name: 'Address', optional: true

  accepts_nested_attributes_for :home_address, allow_destroy: true
  accepts_nested_attributes_for :campus_address, allow_destroy: true

  validates :preferred_first_name, presence: true, length: { in: 1..255 }
  validates :preferred_last_name, presence: true, length: { in: 1..255 }
  validates :umid, 
    presence: true, 
    uniqueness: true, 
    length: { is: 8 },
    format: { with: /\A\d{8}\z/, message: "must be exactly 8 digits" }
  validates :grad_date, presence: true
  validates :degree, presence: true
  validates :receiving_financial_aid, inclusion: { in: [ true, false ] }
  validates :class_level_id, presence: true
  validates :campus_id, presence: true
  validates :school_id, presence: true
  validates :home_address, presence: true
  validates :campus_address, presence: true


  def display_name
    "#{preferred_first_name} #{preferred_last_name}"
  end

  private

  def normalize_names
    self.preferred_first_name = preferred_first_name.strip
    self.preferred_last_name = preferred_last_name.strip
  end
end
