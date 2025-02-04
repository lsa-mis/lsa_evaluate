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
module UserFactoryMethods
  def add_container_role(container)
    container_roles.create(container: container)
  end
end

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@umich.edu" }
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name) { |n| "Last#{n}" }
    sequence(:uniqname) { |n| "uniqname#{n}" }
    password { 'passwordpassword' }
    password_confirmation { 'passwordpassword' }
    display_name { "#{first_name} #{last_name}" }
    uid { uniqname }
    principal_name { email }

    trait :with_judge_role do
      after(:create) do |user|
        user.roles << create(:role, :judge)
      end
    end

    trait :with_container_role do
      after(:create) do |user|
        user.roles << create(:role, :admin)
      end
    end

    trait :with_collection_admin_role do
      after(:create) do |user|
        user.roles << create(:role, :collection_admin)
      end
    end

    trait :with_collection_manager_role do
      after(:create) do |user|
        user.roles << create(:role, :collection_manager)
      end
    end

    trait :axis_mundi do
      after(:create) do |user|
        user.roles << create(:role, :axis_mundi)
      end
    end

    # Alias for backward compatibility
    trait :with_axis_mundi_role do
      axis_mundi
    end

    trait :employee do
      after(:create) do |user|
        user.affiliations << create(:affiliation, name: 'staff')
      end
    end

    trait :student do
      after(:create) do |user|
        user.affiliations << create(:affiliation, name: 'student')
      end
    end

    trait :faculty do
      after(:create) do |user|
        user.affiliations << create(:affiliation, name: 'faculty')
      end
    end
  end
end
