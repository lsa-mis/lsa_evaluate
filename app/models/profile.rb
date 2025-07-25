# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  campus_employee               :boolean          default(FALSE), not null
#  degree                        :string(255)      not null
#  department                    :string(255)
#  financial_aid_description     :text(65535)
#  grad_date                     :date             not null
#  hometown_publication          :string(255)
#  major                         :string(255)
#  pen_name                      :string(255)
#  preferred_first_name          :string(255)      default(""), not null
#  preferred_last_name           :string(255)      default(""), not null
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  umid                          :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_id                     :bigint
#  class_level_id                :bigint
#  school_id                     :bigint
#  user_id                       :bigint           not null
#
# Indexes
#
#  campus_id_idx                     (campus_id)
#  class_level_id_idx                (class_level_id)
#  id_unq_idx                        (id) UNIQUE
#  index_profiles_on_campus_id       (campus_id)
#  index_profiles_on_class_level_id  (class_level_id)
#  index_profiles_on_school_id       (school_id)
#  index_profiles_on_umid            (umid) UNIQUE
#  index_profiles_on_user_id         (user_id)
#  school_id_idx                     (school_id)
#  user_id_idx                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campus_id => campuses.id)
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
class Profile < ApplicationRecord
  before_save :normalize_names

  belongs_to :user
  belongs_to :class_level, optional: true
  belongs_to :school, optional: true
  belongs_to :campus, optional: true
  has_many :entries, dependent: :restrict_with_error

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

  def display_name
    "#{preferred_first_name} #{preferred_last_name}"
  end

  private

  def normalize_names
    self.preferred_first_name = preferred_first_name.strip
    self.preferred_last_name = preferred_last_name.strip
  end
end
