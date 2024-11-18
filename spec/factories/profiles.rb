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

FactoryBot.define do
  factory :profile do
    user
    preferred_first_name { Faker::Name.first_name }
    preferred_last_name { Faker::Name.last_name }
    umid { format('%08d', Faker::Number.number(digits: 8)) }
    class_level
    school
    campus
    major { Faker::Educator.subject }
    department { Faker::Educator.subject }
    grad_date { Faker::Date.forward(days: 365) }
    degree { Faker::Educator.degree }
    receiving_financial_aid { Faker::Boolean.boolean }
    accepted_financial_aid_notice { true }
    campus_employee { Faker::Boolean.boolean }
    financial_aid_description { Faker::Lorem.paragraph }
    hometown_publication { Faker::Address.city }
    pen_name { Faker::Book.author }
    home_address { association :address }
    campus_address { association :address }
  end
end
