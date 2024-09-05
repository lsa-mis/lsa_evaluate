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
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  person_affiliation     :string(255)
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

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :assignments, dependent: :destroy
  has_many :containers, through: :assignments
  has_one :profile, dependent: :destroy

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

  # Method to check for a specific role
  def role?(role_name)
    roles.exists?(kind: role_name)
  end

  def axis_mundi?
    role?('Axis mundi')
  end

  def administrator?
    role?('Container Administrator')
  end

  def manager?
    role?('Container Manager')
  end

  def judge?
    role?('Judge')
  end

  def admin_for_container?(container_id)
    assignments.exists?(container_id:, role: Role.find_by(kind: 'Container Administrator'))
  end

  def manager_for_container?(container_id)
    assignments.exists?(container_id:, role: Role.find_by(kind: 'Container Manager'))
  end

  def display_initials_or_email
    if display_name.present?
      display_name.split.map { |name| name[0].upcase }.join
    else
      email.split('@').first
    end
  end

  def is_employee?
    Rails.logger.info "@@@@@@@@@@ email: #{email} - Person affiliation: #{person_affiliation}"
    %w[employee staff member].any? { |affiliation| person_affiliation&.include?(affiliation) }
  end

  def display_firstname_or_email
    if display_name.present?
      display_name.split.first
    else
      email.split('@').first
    end
  end

  def display_name_or_email
    display_name.presence || email
  end

  def profile_exists?
    profile.present?
  end
end
