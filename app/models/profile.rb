# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  campus_employee               :boolean          default(FALSE), not null
#  degree                        :string(255)
#  department                    :string(255)
#  financial_aid_description     :text(65535)
#  grad_date                     :date
#  hometown_publication          :string(255)
#  legal_first_name              :string(255)      not null
#  legal_last_name               :string(255)      not null
#  major                         :string(255)
#  pen_name                      :string(255)
#  preferred_first_name          :string(255)
#  preferred_last_name           :string(255)
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  umid                          :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_id                     :bigint
#  class_level_id                :bigint
#  school_id                     :bigint
#  user_id                       :bigint           not null
#
class Profile < ApplicationRecord
  before_save :normalize_names

  belongs_to :user
  belongs_to :class_level, optional: true
  belongs_to :school, optional: true
  belongs_to :campus, optional: true
  has_many :entries, dependent: :restrict_with_error

  validates :legal_first_name, presence: true, length: { in: 1..255 }
  validates :legal_last_name, presence: true, length: { in: 1..255 }
  validates :preferred_first_name, length: { maximum: 255 }, allow_blank: true
  validates :preferred_last_name, length: { maximum: 255 }, allow_blank: true
  validates :umid,
    presence: true,
    uniqueness: true,
    length: { is: 8 },
    format: { with: /\A\d{8}\z/, message: 'must be exactly 8 digits' }
  validates :receiving_financial_aid, inclusion: { in: [ true, false ] }
  validates :class_level_id, presence: true

  def display_name
    preferred = [ preferred_first_name, preferred_last_name ].map(&:presence).compact.join(' ')
    return preferred if preferred.present?

    legal = [ legal_first_name, legal_last_name ].map(&:presence).compact.join(' ')
    return legal if legal.present?

    user&.email.to_s
  end

  private

  def normalize_names
    self.legal_first_name = legal_first_name.to_s.strip
    self.legal_last_name = legal_last_name.to_s.strip
    self.preferred_first_name = preferred_first_name.to_s.strip.presence
    self.preferred_last_name = preferred_last_name.to_s.strip.presence
  end
end
