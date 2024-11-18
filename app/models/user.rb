# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string(255)
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  uniqname               :string(255)
#  provider               :string(255)
#  uid                    :string(255)
#  principal_name         :string(255)
#  display_name           :string(255)
#  first_name             :string(255)      default(""), not null
#  last_name              :string(255)      default(""), not null
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
    assignments.joins(:role)
              .exists?(container: container, roles: { kind: role_kinds })
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
