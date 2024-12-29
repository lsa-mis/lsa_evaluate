# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  display_name           :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string(255)      default(""), not null
#  last_name              :string(255)      default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  principal_name         :string(255)
#  provider               :string(255)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  sign_in_count          :integer          default(0), not null
#  uid                    :string(255)
#  uniqname               :string(255)
#  unlock_token           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable, :timeoutable,
         :omniauthable, omniauth_providers: [ :saml ]

  has_many :affiliations, dependent: :destroy
  accepts_nested_attributes_for :affiliations

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :assignments, dependent: :destroy
  has_many :containers, through: :assignments
  has_one :profile, dependent: :destroy
  has_many :judging_assignments, dependent: :restrict_with_error
  has_many :entry_rankings, dependent: :restrict_with_error
  has_many :contest_instances, through: :judging_assignments

  validates :email, :encrypted_password, presence: true
  validates :email, uniqueness: { case_sensitive: false }

  def active_for_authentication?
    super.tap do |active|
      if !active && timedout?(current_sign_in_at)
        # Prevent the flash[:timedout] from being set
        flash[:timedout] = nil
      end
    end
  end

  def axis_mundi?
    @axis_mundi ||= roles.exists?(kind: 'Axis mundi')
  end

  def administrator?
    @administrator ||= roles.exists?(kind: 'Collection Administrator')
  end

  def manager?
    @manager ||= roles.exists?(kind: 'Collection Manager')
  end

  def judge?
    @judge ||= roles.exists?(kind: 'Judge')
  end

  def admin_for_container?(container_id)
    assignments.exists?(container_id:, role: Role.find_by(kind: 'Collection Administrator'))
  end

  def manager_for_container?(container_id)
    assignments.exists?(container_id:, role: Role.find_by(kind: 'Collection Manager'))
  end

  def has_container_role?(container, role_kinds = [ 'Collection Manager', 'Collection Administrator' ])
    role_ids = Role.where(kind: role_kinds).pluck(:id)
    assignments.exists?(container: container, role_id: role_ids)
  end

  def is_employee?
    affiliations.exists?(name: [ 'staff' ])
  end

  def profile_exists?
    profile.present?
  end

  def display_initials_or_uid
    if display_name.present?
      display_name.split.map { |name| name[0].upcase }.join
    else
      uid[0].upcase
    end
  end

  def display_name_or_uid
    display_name.presence || uid
  end

  def display_name_and_uid
    if display_name.present?
      "#{display_name} (#{uid})"
    else
      uid
    end
  end
end
