# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  degree                        :string(255)      not null
#  financial_aid_description     :text(65535)
#  first_name                    :string(255)      default(""), not null
#  grad_date                     :date             not null
#  hometown_publication          :string(255)
#  last_name                     :string(255)      default(""), not null
#  major                         :string(255)
#  pen_name                      :string(255)
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  umid                          :integer          not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_address_id             :bigint
#  campus_id                     :bigint
#  class_level_id                :bigint
#  department_id                 :bigint
#  home_address_id               :bigint
#  school_id                     :bigint
#  user_id                       :bigint           not null
#
# Indexes
#
#  campus_id_idx                        (campus_id)
#  class_level_id_idx                   (class_level_id)
#  id_unq_idx                           (id) UNIQUE
#  index_profiles_on_campus_address_id  (campus_address_id)
#  index_profiles_on_campus_id          (campus_id)
#  index_profiles_on_class_level_id     (class_level_id)
#  index_profiles_on_department_id      (department_id)
#  index_profiles_on_home_address_id    (home_address_id)
#  index_profiles_on_school_id          (school_id)
#  index_profiles_on_user_id            (user_id)
#  school_id_idx                        (school_id)
#  user_id_idx                          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campus_address_id => addresses.id)
#  fk_rails_...  (campus_id => campuses.id)
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (department_id => departments.id)
#  fk_rails_...  (home_address_id => addresses.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :class_level, optional: true
  belongs_to :school, optional: true
  belongs_to :campus, optional: true
  belongs_to :department, optional: true

  belongs_to :home_address, class_name: 'Address', optional: true
  belongs_to :campus_address, class_name: 'Address', optional: true

  accepts_nested_attributes_for :home_address, allow_destroy: true
  accepts_nested_attributes_for :campus_address, allow_destroy: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :umid, presence: true, length: { is: 8 }
  validates :grad_date, presence: true
  validates :degree, presence: true
  validates :receiving_financial_aid, inclusion: { in: [true, false] }
  validates :accepted_financial_aid_notice, inclusion: { in: [true, false] }
  validates :class_level_id, presence: true
  validates :campus_id, presence: true
  validates :school_id, presence: true
  validates :home_address, presence: true
  validates :campus_address, presence: true
end
