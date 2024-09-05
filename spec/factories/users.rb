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
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    # password { "passwordpassword" }
    password { Faker::Internet.password(min_length: 15) }
    uniqname { Faker::Internet.username }
    uid { uniqname }
    principal_name { email }
    display_name { Faker::Name.name }

    trait :employee do
      after(:create) do |user|
        create(:affiliation, user: user, name: 'employee')
      end
    end

    trait :student do
      after(:create) do |user|
        create(:affiliation, user: user, name: 'student')
      end
    end

    trait :faculty do
      after(:create) do |user|
        create(:affiliation, user: user, name: 'faculty')
      end
    end
  end
end
